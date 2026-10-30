#!/usr/bin/env python3
"""《聊斋美人》战斗蒙特卡洛 —— 用真实数据表跑，验证数值曲线是否成立

规则严格按 Battle.gd / GDD 第 3 章实现：
  3 心力 / 回合，抽 5，障回合开始清零，祟弱 ×0.75，缠绕跳过行动，祟毒回合末 -1 层

策略是「普通熟练玩家」的贪心：
  1) 能斩杀就斩杀
  2) 预计要挨的伤害 > 现有障 + 2 就补障
  3) 否则打输出（优先给最低血敌人上毒 / 打最高伤害）
这不是最优 AI，所以结果应理解为「同样操作水平下的期望」，不是理论上限。
"""
import json, random, statistics, sys

D = json.load(open("/tmp/dump.json"))
CARDS = D["cards"]
ENEMIES = D["enemies"]

ENERGY, DRAW, HANDMAX = 3, 5, 10


class Enemy:
    def __init__(self, key):
        e = ENEMIES[key]
        self.key = key
        self.hp = e["hp"]
        self.max_hp = e["hp"]
        self.moves = e["moves"]
        self.i = 0
        self.block = 0
        self.poison = 0
        self.weak = 0
        self.bind = 0
        self.buff = 0

    def intent(self):
        if self.bind > 0:
            return {"kind": "bind"}
        return self.moves[self.i % len(self.moves)]

    def next_move(self):
        self.i += 1


class Sim:
    def __init__(self, deck, enemies, seed=0):
        self.rng = random.Random(seed)
        self.hp = 50
        self.block = 0
        self.poison = 0
        self.weak = 0
        self.grudge = 0
        self.powers = set()
        self.no_attack = False
        self.turn_dmg = 0
        self.enemies = [Enemy(k) for k in enemies]
        self.draw = list(deck)
        self.rng.shuffle(self.draw)
        self.hand = []
        self.discard = []
        self.exhaust = []
        self.turns = 0

    # ---------- 基础动作 ----------
    def draw_cards(self, n):
        for _ in range(n):
            if len(self.hand) >= HANDMAX:
                return
            if not self.draw:
                if not self.discard:
                    return
                self.draw = self.discard
                self.discard = []
                self.rng.shuffle(self.draw)
            self.hand.append(self.draw.pop())

    def alive(self):
        return [e for e in self.enemies if e.hp > 0]

    def incoming(self):
        total = 0
        for e in self.alive():
            it = e.intent()
            if it["kind"] == "attack":
                v = it["val"] + e.buff
                if it.get("hits"):
                    v *= it["hits"]
                if e.weak > 0:
                    v = int(v * 0.75)
                total += v
        return total

    def hit_enemy(self, e, dmg):
        if self.weak > 0:
            dmg = int(dmg * 0.75)
        dmg = max(0, dmg)
        e.hp -= dmg
        if e.hp <= 0:
            e.hp = 0

    def aoe(self, dmg):
        for e in self.alive():
            self.hit_enemy(e, dmg)

    # ---------- 出牌 ----------
    def playable(self, inst):
        key, side = inst
        c = CARDS[key]
        fx = c[side]
        if c["type"] == "curse":
            return False
        if self.no_attack and c["type"] == "attack":
            return False
        return c["cost"] <= self.energy_now

    def best_target(self):
        # 优先残血，其次血少的
        a = self.alive()
        if not a:
            return None
        a.sort(key=lambda e: e.hp)
        return a[0]

    def play(self, inst, target=None):
        key, side = inst
        c = CARDS[key]
        fx = c[side]
        self.energy_now -= c["cost"]
        self.hand.remove(inst)

        if "power" in fx:
            self.powers.add(fx["power"])
        if fx.get("self_hp"):
            self.hp -= int(fx["self_hp"])
        if fx.get("heal"):
            self.hp = min(50, self.hp + int(fx["heal"]))
            self.discard.append((key, self.flip(side)))
            return
        if fx.get("block"):
            self.block += int(fx["block"])
        if fx.get("thorns"):
            self.turn_dmg += int(fx["thorns"])
        if fx.get("draw"):
            self.draw_cards(int(fx["draw"]))
        if fx.get("energy"):
            self.energy_now += int(fx["energy"])
        if fx.get("cleanse"):
            self.poison = 0
            self.weak = 0
        if fx.get("no_attack"):
            self.no_attack = True
        if fx.get("weaken_enemy"):
            t = target or self.best_target()
            if t:
                t.buff -= 0  # 简化：直接减本次意图伤害，在敌方回合结算
                t.weak = max(t.weak, 1)
                t.atk_down = int(fx["weaken_enemy"])

        # 伤害类
        if fx.get("dmg"):
            hits = int(fx.get("hits", 1))
            for _ in range(hits):
                t = target or self.best_target()
                if t:
                    self.hit_enemy(t, int(fx["dmg"]))
        if fx.get("aoe_dmg"):
            self.aoe(int(fx["aoe_dmg"]))
        if fx.get("dmg_if_poison"):
            t = target or self.best_target()
            if t and t.poison > 0:
                self.hit_enemy(t, int(fx["dmg_if_poison"]))
        if fx.get("dmg_if_bound"):
            t = target or self.best_target()
            if t and t.bind > 0:
                self.hit_enemy(t, int(fx["dmg_if_bound"]))

        # 状态
        if fx.get("poison"):
            t = target or self.best_target()
            if t:
                t.poison += int(fx["poison"])
        if fx.get("aoe_poison"):
            for e in self.alive():
                e.poison += int(fx["aoe_poison"])
        if fx.get("weak"):
            t = target or self.best_target()
            if t:
                t.weak += int(fx["weak"])
        if fx.get("aoe_weak"):
            for e in self.alive():
                e.weak += int(fx["aoe_weak"])
        if fx.get("bind"):
            t = target or self.best_target()
            if t:
                t.bind += int(fx["bind"])
        if fx.get("aoe_bind"):
            for e in self.alive():
                e.bind += int(fx["aoe_bind"])

        # 结算型
        sp = fx.get("special")
        if sp:
            t = target or self.best_target()
            if sp == "grudge_bonus" and t:
                self.hit_enemy(t, int(fx.get("dmg", 0)) + (self.grudge // 5) * int(fx.get("mult", 2)))
            elif sp == "grudge_burn":
                dmg = self.grudge * int(fx.get("mult", 2))
                self.grudge = 0
                if t:
                    self.hit_enemy(t, dmg)
            elif sp == "poison_strike" and t:
                self.hit_enemy(t, t.poison * 2)
            elif sp == "poison_scale" and t:
                self.hit_enemy(t, t.poison * int(fx.get("mult", 3)))
                t.poison += int(fx.get("extra_poison", 0))
            elif sp == "poison_consume" and t:
                dmg = t.poison * int(fx.get("mult", 5))
                t.poison = 0
                self.hit_enemy(t, dmg)
            elif sp == "double_poison" and t:
                t.poison *= 2
            elif sp == "block_strike" and t:
                self.hit_enemy(t, self.block)
            elif sp == "block_burn":
                dmg = int(self.block * 1.5)
                self.block = 0
                for e in self.alive():
                    self.hit_enemy(e, dmg)
            elif sp == "draw_per_poison" and t:
                self.draw_cards(min(int(fx.get("max", 3)), t.poison))
            elif sp == "draw_if_bound":
                if any(e.bind > 0 for e in self.alive()):
                    self.draw_cards(int(fx.get("extra", 1)))
            elif sp == "random_bind":
                a = self.alive()
                if a:
                    self.rng.choice(a).bind += int(fx.get("random_bind", 1))
            elif sp == "random_dmg":
                a = self.alive()
                if a:
                    self.hit_enemy(self.rng.choice(a), int(fx.get("random_dmg", 0)))
            elif sp == "poison_splash":
                for e in self.alive():
                    if e.poison > 0:
                        self.hit_enemy(e, int(fx.get("poison_splash", 0)))

        # 弃牌进弃牌堆（消耗/能力除外）
        if fx.get("exhaust") or c["type"] == "power":
            self.exhaust.append((key, side))
        else:
            self.discard.append((key, self.flip(side)))

    @staticmethod
    def flip(side):
        return "ben" if side == "xian" else "xian"

    # ---------- 回合 ----------
    def player_turn(self):
        self.turns += 1
        self.block = 0
        self.turn_dmg = 0
        self.no_attack = False
        self.energy_now = ENERGY
        self.draw_cards(DRAW)

        guard = 0
        while guard < 40:
            guard += 1
            if self.hp <= 0:
                return
            if not self.alive():
                return
            opts = [i for i in self.hand if self.playable(i)]
            if not opts:
                break

            inc = self.incoming()
            need_block = inc > self.block + 2

            # 1) 斩杀
            kill = None
            for i in opts:
                key, side = i
                fx = CARDS[key][side]
                t = self.best_target()
                if not t:
                    break
                dmg = int(fx.get("dmg", 0)) * int(fx.get("hits", 1))
                if dmg and dmg >= t.hp:
                    kill = (i, t)
                    break
            if kill:
                self.play(kill[0], kill[1])
                continue

            # 2) 补障
            if need_block:
                blocks = [(i, CARDS[i[0]][i[1]].get("block", 0)) for i in opts
                          if CARDS[i[0]][i[1]].get("block")]
                if blocks:
                    blocks.sort(key=lambda x: -x[1])
                    self.play(blocks[0][0])
                    continue

            # 3) 输出 / 增益
            def score(i):
                key, side = i
                fx = CARDS[key][side]
                c = CARDS[key]
                if c["type"] == "power":
                    return 14
                s = 0
                if fx.get("dmg"):
                    s = int(fx["dmg"]) * int(fx.get("hits", 1)) / max(1, c["cost"])
                if fx.get("dmg_if_bound"):
                    t = self.best_target()
                    if t and t.bind > 0:
                        s = max(s, int(fx["dmg_if_bound"]) / max(1, c["cost"]))
                if fx.get("dmg_if_poison"):
                    t = self.best_target()
                    if t and t.poison > 0:
                        s = max(s, int(fx["dmg_if_poison"]) / max(1, c["cost"]))
                if fx.get("aoe_dmg"):
                    s = max(s, int(fx["aoe_dmg"]) * len(self.alive()) / max(1, c["cost"]))
                if fx.get("poison"):
                    s = max(s, int(fx["poison"]) * 1.4 / max(1, c["cost"]))
                if fx.get("aoe_poison"):
                    s = max(s, int(fx["aoe_poison"]) * len(self.alive()) * 1.1 / max(1, c["cost"]))
                if fx.get("bind"):
                    t = self.best_target()
                    room = 1 if (t is None or t.bind <= 1) else 0
                    s = max(s, 4.5 * room / max(1, c["cost"]))
                if fx.get("draw"):
                    s = max(s, 2.0)
                if fx.get("special"):
                    s = max(s, 7.0)
                # 血量低时别自损
                if fx.get("self_hp") and self.hp < 22:
                    s *= 0.4
                return s

            opts.sort(key=score, reverse=True)
            best = opts[0]
            if score(best) <= 0.4:
                break
            self.play(best)

        # 回合结束：弃手牌
        self.discard.extend([(k, s) for (k, s) in self.hand])
        self.hand = []

    def enemy_turn(self):
        for e in self.alive():
            if e.bind > 0:
                e.bind -= 1
            else:
                it = e.intent()
                k = it["kind"]
                if k == "attack":
                    v = int(it["val"]) + e.buff
                    if e.weak > 0:
                        v = int(v * 0.75)
                    hits = int(it.get("hits", 1))
                    for _ in range(hits):
                        dmg = v
                        absorbed = min(self.block, dmg)
                        self.block -= absorbed
                        dmg -= absorbed
                        if dmg > 0:
                            self.hp -= dmg
                            self.grudge += 2
                elif k == "debuff":
                    self.poison += int(it["val"])
                elif k == "weak":
                    self.weak += int(it["val"])
                elif k == "defend":
                    e.block += int(it["val"])
                elif k == "buff":
                    e.buff += int(it["val"])
                elif k == "summon":
                    pass
                if it.get("self"):
                    e.hp -= int(it["self"])
            # 敌方回合末：毒结算 + 弱减层
            if e.poison > 0:
                e.hp -= e.poison
                e.poison -= 1
            if e.weak > 0:
                e.weak -= 1
            e.next_move()

        if self.poison > 0:
            self.hp -= self.poison
            self.poison -= 1
        if self.weak > 0:
            self.weak -= 1

    def run(self, max_turns=40):
        while self.turns < max_turns:
            self.player_turn()
            if self.hp <= 0:
                return False, self.hp
            if not self.alive():
                return True, self.hp
            self.enemy_turn()
            if self.hp <= 0:
                return False, self.hp
        return (not self.alive()), self.hp


STARTER = [("sushou", "xian")] * 4 + [("suyi", "xian")] * 4 + \
          [("youyuan", "xian")] * 2 + [("yinlu", "xian")] + [("yi", "xian")]

DECK_L2 = STARTER + [("zhusha", "xian")] * 2 + [("zhangbi", "xian")] + \
          [("binggu", "xian")] + [("yinyi", "xian")] + [("shigu", "xian")] + \
          [("yinlu", "xian")] + [("chansi", "xian")]
DECK_L3 = DECK_L2 + [("shixin", "xian"), ("youhuang", "xian"), ("shuangying", "xian"),
                     ("shiyue", "xian"), ("qingran", "xian") if False else ("qingsi", "xian"),
                     ("suoming", "xian")]


def run_case(name, deck, enemies, n=400):
    wins, hps, turns = 0, [], []
    for s in range(n):
        sim = Sim(deck, enemies, seed=s)
        ok, hp = sim.run()
        wins += 1 if ok else 0
        hps.append(max(0, hp))
        turns.append(sim.turns)
    print("%-22s 敌=%-14s 胜率=%5.1f%%  残血均值=%4.1f  回合=%4.1f" %
          (name, "+".join(enemies), 100.0 * wins / n, statistics.mean(hps), statistics.mean(turns)))
    return wins / n


if __name__ == "__main__":
    print("== 第 1 层 · 初始 12 张 ==")
    run_case("L1 单游魂", STARTER, ["youhun"])
    run_case("L1 双纸人", STARTER, ["zhiren", "zhiren"])
    run_case("L1 树傀", STARTER, ["shukui"])
    run_case("L1 精英姥姥", STARTER, ["laolao"])
    run_case("L1 Boss", STARTER, ["benti"])

    print("\n== 第 2 层 · 19 张（+7 张常见卡）==")
    run_case("L2 双阴差", DECK_L2, ["yinchai", "yinchai"])
    run_case("L2 双饿鬼", DECK_L2, ["egui", "egui"])
    run_case("L2 双水鬼", DECK_L2, ["shuigui", "shuigui"])
    run_case("L2 三阴差", DECK_L2, ["yinchai", "yinchai", "yinchai"])
    run_case("L2 精英鬼母", DECK_L2, ["guimu_small"])
    run_case("L2 Boss", DECK_L2, ["guimu"])

    print("\n== 第 3 层 · 25 张 ==")
    run_case("L3 双狐妖", DECK_L3, ["huyao", "huyao"])
    run_case("L3 双蛇魅", DECK_L3, ["shemei", "shemei"])
    run_case("L3 三狐妖", DECK_L3, ["huyao", "huyao", "huyao"])
    run_case("L3 精英妖将", DECK_L3, ["yaojiang"])
    run_case("L3 Boss", DECK_L3, ["shuyao"])

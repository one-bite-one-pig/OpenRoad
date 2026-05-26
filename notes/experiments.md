# FastRoute Timing-Aware Experiments

研究目标：把 timing criticality 真正灌入 FastRoute 的内部代价函数 / rip-up 排序 / layer assignment，
而不仅靠外层 GR ↔ STA ↔ Resizer 闭环。

参考 baseline commit: `baseline-vanilla` (OpenROAD d088e2269e)

## 实验记录

| Branch | Date | Change | Design | GR WNS (ns) | GR TNS (ns) | Final WNS | Final TNS | Runtime (s) | Notes |
|--------|------|--------|--------|-------------|-------------|-----------|-----------|-------------|-------|
| baseline-vanilla | 2026-05-26 | (vanilla) | gcd / nangate45 | -0.04 | -0.42 | -0.03 | -0.31 | 9 | OpenROAD d088e2269e, clk 0.46ns, 75% util |

## 待办 idea pool

- [ ] 在 maze cost 加 criticality 项：`cost = base + α · (1 − slack_norm) · layer_delay`
- [ ] critical net 优先分配到高层（厚金属、低 RC）
- [ ] 按 criticality 排序 rip-up 顺序
- [ ] 引入 path-based slack（不止 endpoint slack）做更精细加权
- [ ] 实验在更大设计（aes, ibex）上 scale 表现

## 输出/baseline 文件位置速查

```
GR 输入快照: flow/results/nangate45/gcd/base/4_cts.odb
GR 输出快照: flow/results/nangate45/gcd/base/5_1_grt.odb
基线报告:    flow/reports/nangate45/gcd/base/{5_global_route,6_finish}.rpt
基线日志:    flow/logs/nangate45/gcd/base/5_1_grt.log
路由 guide:  flow/results/nangate45/gcd/base/route.guide
```

## 单跑 GR 的最小调用（开发主循环用）

```bash
cd /home/zhujunan/lin_yi_bo/OpenROAD-flow-scripts/flow
openroad -no_init -exit <<'EOF'
read_db results/nangate45/gcd/base/4_cts.odb
global_route -verbose
report_wns
report_tns
EOF
```

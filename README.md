# Mocha

一个专注于个人财务管理的 iOS App，支持债券、股票、黄金的当前持仓快照、资产存放处、独立预算，以及按目标攒钱的金桶。

再平衡功能以债券、股票、黄金、现金各 25% 为目标，支持限定投资项后的买入、卖出和按剩余工作日定投分配。

预算模块支持按分类定义月预算或年预算，并记录支出明细。月预算按每月 1 日进入新周期，年预算按 1 月 1 日进入新周期；历史账目不会被清空，当前周期已用金额会按支出日期动态聚合。

金桶模块通过存入和取出流水动态计算余额，支持可选目标金额、截止日期、归档和负余额提醒；数据不与预算、投资项或存放处联动。

## 运行

直接打开已生成的工程：

```bash
cd Mocha
open Mocha.xcodeproj
```

选择模拟器后运行即可。数据通过 SwiftData 保存在设备本地。

`project.yml` 是工程的单一配置源。新增目录或 Target 后，可安装 XcodeGen 并运行
`xcodegen generate` 重新生成工程，避免长期手工维护易冲突的 `project.pbxproj`。

## 结构

- `App/`：应用入口
- `Core/`：跨模块可复用的格式化和 UI 基础设施
- `Features/Investment/Domain/`：投资快照、存放处模型与汇总规则
- `Features/Investment/Views/`：投资模块 UI
- `Features/Budget/Domain/`：预算定义、支出账目和周期聚合规则
- `Features/Budget/Views/`：预算模块 UI
- `Features/GoldenBucket/Domain/`：金桶、存取流水和目标进度规则
- `Features/GoldenBucket/Views/`：金桶模块 UI
- `Features/Settings/Views/`：设置模块 UI

每项投资直接记录持仓金额和总盈亏，不追踪成本与交易历史；现金底层盈亏固定为 0，用户侧只录入持仓金额。

# 预算模块设计

## 目标

在 Mocha 中新增与投资独立的预算模块，用于定义消费预算并记录支出。预算模块聚焦消费控制，不改变现有投资持仓快照、存放处、再平衡逻辑。

## 范围

本次实现包含：

- 新增预算定义：分类名称、金额、周期。
- 新增支出记账：选择预算、金额、支出日期、备注。
- 新增预算 Tab：首页展示当前周期预算卡片，详情页展示该预算下的支出明细。
- 支持月预算和年预算，月预算按每月 1 日进入新周期，年预算按 1 月 1 日进入新周期。
- 支持历史日期补记，账目按支出日期归属周期。
- 支持预算归档，归档后不出现在新记账选择中，历史账目保留。

不包含：

- 收入记录。
- 与投资项或存放处的资金联动。
- 多币种。
- 预算额度版本化。
- 后台定时任务。

## 数据模型

### Budget

预算定义使用 SwiftData `@Model`，字段如下：

- `name: String`：分类名称，非空。
- `amount: Decimal`：预算金额，必须大于等于 0。
- `periodRawValue: String`：预算周期，取值为月或年。
- `isArchived: Bool`：是否归档。
- `createdAt: Date`：创建时间。
- `updatedAt: Date`：更新时间。

派生属性：

- `period: BudgetPeriod`：把 `periodRawValue` 映射为枚举。

同一个未归档预算中，分类名称不允许重复。为避免 SwiftData 唯一约束迁移复杂度，先在保存入口做应用层校验。

### BudgetPeriod

预算周期枚举：

- `monthly = "月"`
- `yearly = "年"`

枚举提供当前周期范围计算：

- 月周期：从当前月份 1 日 00:00 到下个月 1 日 00:00。
- 年周期：从当前年份 1 月 1 日 00:00 到下一年 1 月 1 日 00:00。

计算使用 `Calendar.current`，只基于本地日期语义。

### BudgetEntry

支出账目使用 SwiftData `@Model`，字段如下：

- `budget: Budget?`：所属预算。
- `amount: Decimal`：支出金额，必须大于 0。
- `spentAt: Date`：支出日期。
- `note: String`：备注。
- `createdAt: Date`：创建时间。
- `updatedAt: Date`：更新时间。

账目是事实记录，不保存周期字段，不保存预算快照金额。当前周期已用金额从 `BudgetEntry` 按 `spentAt` 聚合得到。

## 周期与重置语义

预算不会在每月 1 日或每年 1 月 1 日清空字段。周期重置通过日期范围投影实现：

- 展示月预算时，只统计当前月范围内的账目。
- 展示年预算时，只统计当前年范围内的账目。
- 补记历史日期时，账目自动归属历史周期；当前周期展示不受无关历史账目影响。

这种方式避免定时任务和跨日数据写入风险，也保留完整历史。

## UI 结构

### App 导航

在 `MochaRootView` 的 `TabView` 中新增第三个 Tab：

- 标题：预算
- 图标：`calendar.badge.clock`
- 内容：`BudgetDashboardView`

### 预算首页

预算首页使用 `NavigationStack` + `ScrollView`，沿用现有投资首页的视觉语言。

内容：

- 当前月预算汇总：当前周期月预算已用金额 / 总金额。
- 当前年预算汇总：当前周期年预算已用金额 / 总金额。
- 未归档预算列表，每项展示：
  - 分类名称。
  - 周期。
  - 当前周期已用金额。
  - 预算金额。
  - 剩余金额或超支金额。
  - 进度条。

操作：

- `+预算`：打开预算定义编辑器。
- `+记账`：打开支出记账编辑器。
- `归档`：进入归档预算列表。

空状态：

- 无预算时展示 `ContentUnavailableView`，提示创建第一个预算。

### 预算详情

预算详情页展示单个预算的当前周期和账目明细。

内容：

- 当前周期预算概览：已用、预算金额、剩余或超支。
- 当前周期支出明细列表，按 `spentAt` 倒序。
- 备注为空时只展示金额和日期。

操作：

- 编辑预算。
- 归档预算。
- 删除账目。

### 预算编辑器

预算编辑器使用 `Form`：

- 分类名称。
- 周期 Picker：月 / 年。
- 金额。

保存规则：

- 名称去除首尾空白后不能为空。
- 金额不能小于 0。
- 未归档预算中不能存在同名预算。
- 编辑已有预算时，修改立即影响当前周期展示，不修改历史账目。

### 记账编辑器

记账编辑器使用 `Form`：

- 预算 Picker：只展示未归档预算。
- 支出金额。
- 支出日期，允许选择历史日期。
- 备注。

保存规则：

- 必须选择预算。
- 金额必须大于 0。
- 允许超支，超支后首页和详情展示负剩余或超支金额。

## 边界行为

- 归档预算：设置 `isArchived = true`，不删除预算和账目。
- 归档预算不出现在新记账 Picker 中。
- 已归档预算可在归档列表中查看详情和历史账目。
- 删除账目只删除该条 `BudgetEntry`，预算统计立即按剩余账目重算。
- 删除预算不做物理删除入口，统一使用归档，降低误删风险。
- 预算金额为 0 时允许保存；只要产生支出即显示超支。

## 测试策略

新增预算领域单元测试，覆盖：

- 月周期范围：当月 1 日到下月 1 日。
- 年周期范围：1 月 1 日到下一年 1 月 1 日。
- 当前周期已用金额聚合。
- 历史日期账目不会计入当前周期。
- 超支时剩余金额为负。
- 归档预算不影响历史账目聚合。

构建验证使用：

```bash
xcodebuild -project Mocha.xcodeproj -scheme Mocha -sdk iphonesimulator -configuration Debug -derivedDataPath /private/tmp/MochaDerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

## 实现文件

预计新增：

- `Mocha/Features/Budget/Domain/Budget.swift`
- `Mocha/Features/Budget/Domain/BudgetPeriod.swift`
- `Mocha/Features/Budget/Domain/BudgetEntry.swift`
- `Mocha/Features/Budget/Domain/BudgetProgress.swift`
- `Mocha/Features/Budget/Views/BudgetDashboardView.swift`
- `Mocha/Features/Budget/Views/BudgetDetailView.swift`
- `Mocha/Features/Budget/Views/BudgetEditorView.swift`
- `Mocha/Features/Budget/Views/BudgetEntryEditorView.swift`
- `Mocha/Features/Budget/Views/ArchivedBudgetListView.swift`
- `MochaTests/BudgetPeriodTests.swift`
- `MochaTests/BudgetProgressTests.swift`

预计修改：

- `Mocha/App/MochaApp.swift`
- `project.yml`
- `Mocha.xcodeproj/project.pbxproj`
- `README.md`

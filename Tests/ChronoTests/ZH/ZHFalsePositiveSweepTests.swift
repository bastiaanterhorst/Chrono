// ZHFalsePositiveSweepTests.swift - One broad sweep: ordinary task names must never produce a date.
import Testing
import Foundation
@testable import Chrono

/// A single sweep over ordinary Chinese task names, in which **any** output is a defect.
///
/// This is the safety net for a locale that recognises a bare `15号` and a bare `十点` — two
/// additions that each opened a new way to be wrong. In a to-do app the asymmetry is stark: a
/// missed date costs one tap, while a hallucinated date silently files the task on the wrong day and
/// the user finds out when they miss it. So the ZH locale is built to prefer a miss, and this suite
/// is what proves it still does.
///
/// `ZHCollisionTests` documents *why* each individual guard exists, one collision at a time. This
/// suite deliberately has no per-case reasoning: it is a corpus, run in both forward modes, and it
/// gets appended to whenever a new matching surface is added.
@Suite("ZH — false-positive sweep")
struct ZHFalsePositiveSweepTests {

    /// Every string here is a plausible thing to write in a to-do list, and none of them is a date.
    private static let ordinaryTaskNames = [
        // 号 as an identifier — the risk opened by reading a bare day of the month
        "买5号电池", "3号线换乘", "5号楼下", "会议室2号", "房间12号", "工位3号", "2号选手",
        "大号咖啡", "中号衣服", "42号鞋", "手机号码", "查学号", "银行卡号", "订单号",
        "1号店", "5号窗口", "3号柜台", "8号风球", "2号机器", "第5号文件", "车厢3号",

        // 点 as the measure word for enumerated items — the risk in reading a bare hour
        "记录3点建议", "总结3点意见", "提出2点要求", "有3点问题", "讨论4点内容",
        "分为5点说明", "列出3点原因", "归纳两点共识", "补充1点内容", "强调3点要求",
        "记录三点建议", "总结两点经验", "汇总4点反馈", "概括3点意见",

        // 月 / 年 inside ordinary vocabulary
        "这个月亮很美", "蜜月旅行", "他很年轻", "年纪大了", "说明年度计划",
        "月刊订阅", "青年活动", "童年回忆",

        // 底 / 初 as ordinary words — the risk opened by reading 月底 and 年初
        "海底世界", "彻底清理", "初中同学", "当初的想法", "底稿整理", "初步方案",
        "到底怎么办", "基础打底",

        // Collisions the locale already guarded, re-checked against the new parsers
        "十分重要", "一点点", "有点累", "吃点心", "每天跑步", "每周三", "超过3天",
        "我喜欢日本", "生日快乐", "天气很好", "周围很安静", "下班后回家", "等一下",
        "买3个苹果", "看第三章", "打印5份文件", "联系张三", "买一斤肉", "第5次尝试",
        "充值100元", "跑步5公里", "回复12封邮件", "整理2019年的照片", "读完前三章"
    ]

    @Test func noOrdinaryTaskNameProducesADate() {
        var offenders: [String] = []
        for text in Self.ordinaryTaskNames {
            // Both modes: a host may or may not ask for forward dates, and the forward path has its
            // own month/year rolling that could resurrect a match the plain path rejects.
            for forward in [false, true] {
                let results = zhParse(text, forward: forward)
                if !results.isEmpty {
                    offenders.append("「\(text)」(forward: \(forward)) → \(results.map { "'\($0.text)'" }.joined(separator: ", "))")
                }
            }
        }
        let report = offenders.joined(separator: "\n")
        #expect(offenders.isEmpty, "\(offenders.count) ordinary task name(s) produced a date:\n\(report)")
    }
}

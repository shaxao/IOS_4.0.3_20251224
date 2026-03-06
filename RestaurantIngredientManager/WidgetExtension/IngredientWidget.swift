//
//  IngredientWidget.swift
//  RestaurantIngredientManager Widget Extension
//
//  主屏幕Widget
//

import WidgetKit
import SwiftUI

/// Widget时间线提供者
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> IngredientEntry {
        IngredientEntry(date: Date(), lowStockCount: 0, expiringCount: 0, totalItems: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (IngredientEntry) -> ()) {
        let entry = IngredientEntry(date: Date(), lowStockCount: 3, expiringCount: 5, totalItems: 120)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [IngredientEntry] = []

        // 从共享数据源获取数据
        let data = loadWidgetData()
        
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = IngredientEntry(
                date: entryDate,
                lowStockCount: data.lowStockCount,
                expiringCount: data.expiringCount,
                totalItems: data.totalItems
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadWidgetData() -> (lowStockCount: Int, expiringCount: Int, totalItems: Int) {
        // 从App Group共享数据
        if let sharedDefaults = UserDefaults(suiteName: "group.com.restaurant.ingredientmanager") {
            let lowStock = sharedDefaults.integer(forKey: "lowStockCount")
            let expiring = sharedDefaults.integer(forKey: "expiringCount")
            let total = sharedDefaults.integer(forKey: "totalItems")
            return (lowStock, expiring, total)
        }
        return (0, 0, 0)
    }
}

/// Widget数据条目
struct IngredientEntry: TimelineEntry {
    let date: Date
    let lowStockCount: Int
    let expiringCount: Int
    let totalItems: Int
}

/// 小型Widget视图
struct SmallWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2)
                Text("食材库存")
                    .font(.headline)
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.totalItems)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("总数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if entry.lowStockCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("\(entry.lowStockCount)")
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                    }
                    
                    if entry.expiringCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("\(entry.expiringCount)")
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

/// 中型Widget视图
struct MediumWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：总览
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                    Text("食材库存")
                        .font(.headline)
                }
                
                Spacer()
                
                Text("\(entry.totalItems)")
                    .font(.system(size: 36, weight: .bold))
                Text("总数")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // 右侧：警告
            VStack(spacing: 12) {
                // 低库存
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    VStack(alignment: .leading) {
                        Text("\(entry.lowStockCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("低库存")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // 即将过期
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading) {
                        Text("\(entry.expiringCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("即将过期")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

/// 大型Widget视图
struct LargeWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2)
                Text("食材库存管理")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 统计卡片
            HStack(spacing: 12) {
                StatCard(
                    icon: "list.bullet",
                    value: "\(entry.totalItems)",
                    label: "总数",
                    color: .blue
                )
                
                StatCard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(entry.lowStockCount)",
                    label: "低库存",
                    color: .red
                )
                
                StatCard(
                    icon: "clock.fill",
                    value: "\(entry.expiringCount)",
                    label: "即将过期",
                    color: .orange
                )
            }
            
            Spacer()
            
            // 快速操作提示
            HStack {
                Image(systemName: "hand.tap")
                    .font(.caption)
                Text("点击打开应用查看详情")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// 统计卡片
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Widget配置
@main
struct IngredientWidget: Widget {
    let kind: String = "IngredientWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                IngredientWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                IngredientWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("食材库存")
        .description("快速查看食材库存状态和提醒")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Widget入口视图
struct IngredientWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    IngredientWidget()
} timeline: {
    IngredientEntry(date: .now, lowStockCount: 3, expiringCount: 5, totalItems: 120)
}

#Preview(as: .systemMedium) {
    IngredientWidget()
} timeline: {
    IngredientEntry(date: .now, lowStockCount: 3, expiringCount: 5, totalItems: 120)
}

#Preview(as: .systemLarge) {
    IngredientWidget()
} timeline: {
    IngredientEntry(date: .now, lowStockCount: 3, expiringCount: 5, totalItems: 120)
}

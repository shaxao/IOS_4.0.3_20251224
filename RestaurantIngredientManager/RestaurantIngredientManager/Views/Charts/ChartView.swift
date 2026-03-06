//
//  ChartView.swift
//  RestaurantIngredientManager
//
//  图表可视化视图
//

import SwiftUI
import Charts

/// 图表类型
enum ChartType {
    case bar
    case line
    case pie
    case donut
}

/// 图表数据点
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

/// 通用图表视图
struct ChartView: View {
    let title: String
    let data: [ChartDataPoint]
    let chartType: ChartType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            switch chartType {
            case .bar:
                BarChartView(data: data)
            case .line:
                LineChartView(data: data)
            case .pie:
                PieChartView(data: data)
            case .donut:
                DonutChartView(data: data)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/// 柱状图
struct BarChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(data) { point in
                BarMark(
                    x: .value("类别", point.label),
                    y: .value("数量", point.value)
                )
                .foregroundStyle(point.color)
            }
            .frame(height: 200)
            .padding()
        } else {
            // iOS 15 fallback
            CustomBarChart(data: data)
        }
    }
}

/// 折线图
struct LineChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(data) { point in
                LineMark(
                    x: .value("时间", point.label),
                    y: .value("数量", point.value)
                )
                .foregroundStyle(point.color)
            }
            .frame(height: 200)
            .padding()
        } else {
            CustomLineChart(data: data)
        }
    }
}

/// 饼图
struct PieChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(data) { point in
                SectorMark(
                    angle: .value("数量", point.value)
                )
                .foregroundStyle(point.color)
            }
            .frame(height: 200)
            .padding()
        } else {
            CustomPieChart(data: data)
        }
    }
}

/// 环形图
struct DonutChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(data) { point in
                SectorMark(
                    angle: .value("数量", point.value),
                    innerRadius: .ratio(0.5)
                )
                .foregroundStyle(point.color)
            }
            .frame(height: 200)
            .padding()
        } else {
            CustomDonutChart(data: data)
        }
    }
}

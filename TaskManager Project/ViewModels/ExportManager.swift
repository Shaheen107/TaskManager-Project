
//  ExportManager.swift
//  TaskManager Project
//
//  Created by AppleDev on 15/10/2025.
//

import Foundation
import UIKit
import PDFKit

class ExportManager {
    
    // MARK: - Export to CSV
    static func exportToCSV(tasks: [TaskItems]) -> URL? {
        var csvText = "Title,Description,Priority,Category,Status,Created Date,Due Date,Completed Date\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for task in tasks {
            let title = task.title.replacingOccurrences(of: ",", with: ";")
            let description = task.description.replacingOccurrences(of: ",", with: ";")
            let priority = task.priority.rawValue
            let category = task.category.rawValue
            let status = task.isCompleted ? "Completed" : "Pending"
            let createdDate = dateFormatter.string(from: task.createdDate)
            let dueDate = task.dueDate != nil ? dateFormatter.string(from: task.dueDate!) : "N/A"
            let completedDate = task.completedDate != nil ? dateFormatter.string(from: task.completedDate!) : "N/A"
            
            let row = "\(title),\(description),\(priority),\(category),\(status),\(createdDate),\(dueDate),\(completedDate)\n"
            csvText.append(row)
        }
        
        // Save to temporary directory
        let fileName = "TaskManager_Export_\(Date().timeIntervalSince1970).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            print("✅ CSV exported successfully to: \(path)")
            return path
        } catch {
            print("❌ Failed to export CSV: \(error)")
            return nil
        }
    }
    
    // MARK: - Export to PDF
    static func exportToPDF(tasks: [TaskItems], statistics: TaskStatistics) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "TaskManager App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Task Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "TaskManager_Report_\(Date().timeIntervalSince1970).pdf"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try renderer.writePDF(to: path) { context in
                context.beginPage()
                
                var yPosition: CGFloat = 50
                
                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ]
                let title = "Task Manager Report"
                title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
                yPosition += 40
                
                // Date
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .short
                
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.gray
                ]
                let dateString = "Generated on: \(dateFormatter.string(from: Date()))"
                dateString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: dateAttributes)
                yPosition += 30
                
                // Statistics Section
                let sectionAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ]
                "Statistics Overview".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25
                
                let statsAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkGray
                ]
                
                let stats = [
                    "Total Tasks: \(statistics.totalTasks)",
                    "Completed Tasks: \(statistics.completedTasks)",
                    "Pending Tasks: \(statistics.pendingTasks)",
                    "Overdue Tasks: \(statistics.overdueTasks)",
                    "Completion Rate: \(statistics.completionRateString)",
                    "Tasks Completed Today: \(statistics.tasksCompletedToday)"
                ]
                
                for stat in stats {
                    stat.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: statsAttributes)
                    yPosition += 20
                }
                
                yPosition += 20
                
                // Tasks Section
                "Task List".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25
                
                let taskAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                
                let taskDetailAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.gray
                ]
                
                for (index, task) in tasks.enumerated() {
                    // Check if we need a new page
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = 50
                    }
                    
                    // Task number and title
                    let taskTitle = "\(index + 1). \(task.title)"
                    taskTitle.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: taskAttributes)
                    yPosition += 18
                    
                    // Task details
                    let status = task.isCompleted ? "✓ Completed" : "○ Pending"
                    let priority = "Priority: \(task.priority.rawValue)"
                    let category = "Category: \(task.category.rawValue)"
                    
                    status.draw(at: CGPoint(x: 90, y: yPosition), withAttributes: taskDetailAttributes)
                    yPosition += 15
                    
                    priority.draw(at: CGPoint(x: 90, y: yPosition), withAttributes: taskDetailAttributes)
                    yPosition += 15
                    
                    category.draw(at: CGPoint(x: 90, y: yPosition), withAttributes: taskDetailAttributes)
                    yPosition += 15
                    
                    if let dueDate = task.dueDate {
                        let dueDateString = "Due: \(dateFormatter.string(from: dueDate))"
                        dueDateString.draw(at: CGPoint(x: 90, y: yPosition), withAttributes: taskDetailAttributes)
                        yPosition += 15
                    }
                    
                    if !task.description.isEmpty {
                        let desc = "Description: \(task.description)"
                        let descRect = CGRect(x: 90, y: yPosition, width: pageWidth - 140, height: 100)
                        desc.draw(in: descRect, withAttributes: taskDetailAttributes)
                        yPosition += 30
                    }
                    
                    yPosition += 10
                }
                
                // Footer
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.lightGray
                ]
                let footer = "Generated by TaskManager App"
                footer.draw(at: CGPoint(x: 50, y: pageHeight - 50), withAttributes: footerAttributes)
            }
            
            print("✅ PDF exported successfully to: \(path)")
            return path
        } catch {
            print("❌ Failed to export PDF: \(error)")
            return nil
        }
    }
}

import XCTest
import Combine
@testable import RestaurantIngredientManager

final class PrinterStateSyncTests: XCTestCase {
    func testReconnectAfterStatusFailure() async {
        let suiteName = "PrinterStateSyncTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let service = MockPrinterService()
        let vm = await MainActor.run {
            PrinterViewModel(printerService: service, defaults: defaults, enableHeartbeat: false)
        }
        let printer = PrinterDevice(bluetoothName: "BT-01")
        await vm.connect(to: printer)
        service.shouldFailStatus = true
        await vm.refreshStatus()
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertGreaterThanOrEqual(service.connectCallCount, 2)
    }

    func testRestorePairedPrinterAfterRestart() async {
        let suiteName = "PrinterStateSyncTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let service = MockPrinterService()
        let printer = PrinterDevice(wifiName: "WiFiPrinter", ipAddress: "192.168.1.20")

        let first = await MainActor.run {
            PrinterViewModel(printerService: service, defaults: defaults, enableHeartbeat: false)
        }
        await first.connect(to: printer)

        let second = await MainActor.run {
            PrinterViewModel(printerService: service, defaults: defaults, enableHeartbeat: false)
        }
        let restored = await MainActor.run { second.connectedPrinter }
        XCTAssertEqual(restored?.name, printer.name)
        XCTAssertEqual(restored?.ipAddress, printer.ipAddress)
    }
}

private final class MockPrinterService: PrinterServiceProtocol {
    var connectedPrinter: PrinterDevice?
    var currentStatus: PrinterStatus = PrinterStatus()
    var statusSubject = CurrentValueSubject<PrinterStatus, Never>(PrinterStatus())
    var statusPublisher: AnyPublisher<PrinterStatus, Never> { statusSubject.eraseToAnyPublisher() }
    var connectCallCount = 0
    var shouldFailStatus = false

    func scanForBluetoothPrinters() async throws -> [PrinterDevice] {
        []
    }

    func discoverWiFiPrinters(timeout: Float) async throws -> [PrinterDevice] {
        []
    }

    func connect(to printer: PrinterDevice) async throws {
        connectCallCount += 1
        connectedPrinter = printer
        currentStatus = PrinterStatus(isConnected: true, paperStatus: .normal, batteryLevel: 80, coverStatus: .closed)
        statusSubject.send(currentStatus)
    }

    func disconnect() async throws {
        connectedPrinter = nil
        currentStatus = PrinterStatus()
        statusSubject.send(currentStatus)
    }

    func getPrinterStatus() async throws -> PrinterStatus {
        if shouldFailStatus {
            shouldFailStatus = false
            throw PrinterServiceError.notConnected
        }
        return PrinterStatus(isConnected: true, paperStatus: .normal, batteryLevel: 80, coverStatus: .closed)
    }

    func printLabel(template: LabelTemplate, data: [String: String]) async throws {}

    func printBatch(labels: [(LabelTemplate, [String : String])]) async throws -> BatchPrintResult {
        BatchPrintResult(totalJobs: labels.count, successfulJobs: labels.count, failedJobs: [])
    }
}

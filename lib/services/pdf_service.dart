import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:skycypher/models/maintenance_log.dart';
import 'package:skycypher/screens/voice_inspection_screen.dart';

class PdfService {
  static Future<void> generateMaintenanceLogPdf(
      List<MaintenanceLog> logs) async {
    final pdf = pw.Document();

    // Get current date for the report
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(now);

    // Add a page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'AIRCRAFT MAINTENANCE LOG',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Generated: $formattedDate',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 16),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                // Table headers
                [
                  '#',
                  'Date',
                  'Aircraft',
                  'Registration',
                  'Component',
                  'Inspector',
                  'Location',
                ],
                // Table data
                for (int i = 0; i < logs.length; i++)
                  [
                    '${i + 1}',
                    logs[i].date.isNotEmpty ? logs[i].date : 'N/A',
                    logs[i].aircraft.isNotEmpty
                        ? logs[i].aircraft
                        : (logs[i].aircraftModel.isNotEmpty
                            ? logs[i].aircraftModel
                            : 'N/A'),
                    logs[i].aircraftRegNumber.isNotEmpty
                        ? logs[i].aircraftRegNumber
                        : 'N/A',
                    logs[i].component.isNotEmpty ? logs[i].component : 'N/A',
                    logs[i].inspectedByFullName.isNotEmpty
                        ? logs[i].inspectedByFullName
                        : (logs[i].inspectedBy.isNotEmpty
                            ? logs[i].inspectedBy
                            : 'N/A'),
                    logs[i].location.isNotEmpty ? logs[i].location : 'N/A',
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 10,
              ),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
                6: pw.Alignment.centerLeft,
              },
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FixedColumnWidth(30), // #
                1: const pw.FixedColumnWidth(80), // Date
                2: const pw.FlexColumnWidth(1.5), // Aircraft
                3: const pw.FixedColumnWidth(80), // Registration
                4: const pw.FlexColumnWidth(1.2), // Component
                5: const pw.FlexColumnWidth(1.2), // Inspector
                6: const pw.FlexColumnWidth(1.0), // Location
              },
            ),

            // Add detailed information for each log
            pw.SizedBox(height: 20),
            pw.Text(
              'DETAILED MAINTENANCE RECORDS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),

            for (int i = 0; i < logs.length; i++) ...[
              if (i > 0) pw.SizedBox(height: 20),
              _buildLogDetail(logs[i], i + 1),
            ],
          ];
        },
      ),
    );

    // Save the PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/maintenance_log_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildLogDetail(MaintenanceLog log, int index) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with log number
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Log #$index',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  log.date.isNotEmpty ? log.date : 'N/A',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Aircraft Information
          _buildSectionTitle('AIRCRAFT INFORMATION'),
          pw.SizedBox(height: 6),
          _buildInfoRow('Aircraft Model:',
              log.aircraftModel.isNotEmpty ? log.aircraftModel : 'N/A'),
          _buildInfoRow('Aircraft Registration:',
              log.aircraftRegNumber.isNotEmpty ? log.aircraftRegNumber : 'N/A'),
          _buildInfoRow(
              'Aircraft:', log.aircraft.isNotEmpty ? log.aircraft : 'N/A'),
          pw.SizedBox(height: 12),

          // Maintenance Details
          _buildSectionTitle('MAINTENANCE DETAILS'),
          pw.SizedBox(height: 6),
          _buildInfoRow(
              'Component:', log.component.isNotEmpty ? log.component : 'N/A'),
          _buildInfoRow('Parts/Components:',
              log.aircraftParts.isNotEmpty ? log.aircraftParts : 'N/A'),
          _buildInfoRow('Maintenance Task:',
              log.maintenanceTask.isNotEmpty ? log.maintenanceTask : 'N/A'),
          _buildInfoRow(
              'Location:', log.location.isNotEmpty ? log.location : 'N/A'),
          pw.SizedBox(height: 12),

          // Time Information
          _buildSectionTitle('TIME INFORMATION'),
          pw.SizedBox(height: 6),
          _buildInfoRow('Date & Time Started:',
              log.dateTimeStarted.isNotEmpty ? log.dateTimeStarted : 'N/A'),
          _buildInfoRow('Date & Time Ended:',
              log.dateTimeEnded.isNotEmpty ? log.dateTimeEnded : 'N/A'),
          pw.SizedBox(height: 12),

          // Inspection Information
          _buildSectionTitle('INSPECTION INFORMATION'),
          pw.SizedBox(height: 6),
          _buildInfoRow(
              'Inspected By:',
              log.inspectedByFullName.isNotEmpty
                  ? log.inspectedByFullName
                  : (log.inspectedBy.isNotEmpty ? log.inspectedBy : 'N/A')),
          _buildInfoRow(
              'Detailed Inspection:',
              log.detailedInspection.isNotEmpty
                  ? log.detailedInspection
                  : 'N/A'),
          pw.SizedBox(height: 12),

          // Issue and Action Information
          _buildSectionTitle('ISSUE & ACTION'),
          pw.SizedBox(height: 6),
          _buildInfoRow('Reported Issue:',
              log.reportedIssue.isNotEmpty ? log.reportedIssue : 'N/A'),
          _buildInfoRow('Discrepancy:',
              log.discrepancy.isNotEmpty ? log.discrepancy : 'N/A'),
          _buildInfoRow('Corrective Action:',
              log.correctiveAction.isNotEmpty ? log.correctiveAction : 'N/A'),
          _buildInfoRow('Action Taken:',
              log.actionTaken.isNotEmpty ? log.actionTaken : 'N/A'),
          pw.SizedBox(height: 12),

          // Remarks
          _buildSectionTitle('REMARKS'),
          pw.SizedBox(height: 6),
          _buildInfoRow('Component Remarks:',
              log.componentRemarks.isNotEmpty ? log.componentRemarks : 'N/A'),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue800,
        decoration: pw.TextDecoration.underline,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> generateInspectionReportPdf({
    required String aircraftModel,
    required String rpNumber,
    required String? userType,
    required String mechanicCategory,
    required List<InspectionItem> inspectionItems,
  }) async {
    final pdf = pw.Document();

    // Get current date for the report
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(now);
    final formattedTime = DateFormat('hh:mm a').format(now);

    // Calculate statistics
    final completedItems =
        inspectionItems.where((item) => item.isCompleted).length;
    final warningItems =
        inspectionItems.where((item) => item.hasWarning).length;
    final pendingItems = inspectionItems.length - completedItems - warningItems;

    // Add a page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'AIRCRAFT INSPECTION REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Generated: $formattedDate at $formattedTime',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 16),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Aircraft Information Section
            _buildSectionHeader('AIRCRAFT INFORMATION'),
            pw.SizedBox(height: 12),
            _buildInfoGrid([
              _buildInfoCard('Aircraft Model', aircraftModel),
              _buildInfoCard('RP Number', rpNumber),
              _buildInfoCard('Inspector Type', userType ?? 'Unknown'),
              if (userType == 'Mechanic')
                _buildInfoCard('Category', mechanicCategory),
            ]),
            pw.SizedBox(height: 20),

            // Inspection Summary Section
            _buildSectionHeader('INSPECTION SUMMARY'),
            pw.SizedBox(height: 12),
            _buildSummaryCards(completedItems, warningItems, pendingItems,
                inspectionItems.length),
            pw.SizedBox(height: 20),

            // Detailed Inspection Results
            _buildSectionHeader('DETAILED INSPECTION RESULTS'),
            pw.SizedBox(height: 12),

            // Table with inspection items
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                // Table headers
                [
                  '#',
                  'Inspection Item',
                  'Status',
                  'Time',
                ],
                // Table data
                for (int i = 0; i < inspectionItems.length; i++)
                  [
                    '${i + 1}',
                    inspectionItems[i].title,
                    inspectionItems[i].isCompleted
                        ? 'Completed'
                        : inspectionItems[i].hasWarning
                            ? 'Warning'
                            : 'Pending',
                    inspectionItems[i].isCompleted &&
                            inspectionItems[i].completedAt != null
                        ? DateFormat('hh:mm a')
                            .format(inspectionItems[i].completedAt!)
                        : inspectionItems[i].hasWarning &&
                                inspectionItems[i].warningAt != null
                            ? DateFormat('hh:mm a')
                                .format(inspectionItems[i].warningAt!)
                            : 'N/A',
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 10,
              ),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FixedColumnWidth(30), // #
                1: const pw.FlexColumnWidth(2.5), // Inspection Item
                2: const pw.FixedColumnWidth(80), // Status
                3: const pw.FixedColumnWidth(60), // Time
              },
            ),

            // Detailed information for each item
            pw.SizedBox(height: 20),
            pw.Text(
              'INSPECTION DETAILS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),

            for (int i = 0; i < inspectionItems.length; i++) ...[
              if (i > 0) pw.SizedBox(height: 16),
              _buildInspectionItemDetail(inspectionItems[i], i + 1),
            ],

            // Footer note
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Notes:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'This report was generated automatically from a voice-controlled inspection system. '
                    'All inspection items were completed using hands-free voice commands.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Save the PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/inspection_report_${aircraftModel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoGrid(List<pw.Widget> cards) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards,
    );
  }

  static pw.Widget _buildInfoCard(String label, String value) {
    return pw.Container(
      width: 180,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.black,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCards(
      int completed, int warnings, int pending, int total) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSummaryCard(
            'Completed',
            '$completed/$total',
            PdfColors.green,
            PdfColors.green100,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _buildSummaryCard(
            'Warnings',
            warnings.toString(),
            PdfColors.orange,
            PdfColors.orange100,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _buildSummaryCard(
            'Pending',
            pending.toString(),
            PdfColors.grey,
            PdfColors.grey200,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(
      String label, String value, PdfColor color, PdfColor backgroundColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInspectionItemDetail(InspectionItem item, int index) {
    PdfColor statusColor;
    String statusText;

    if (item.isCompleted) {
      statusColor = PdfColors.green;
      statusText = 'COMPLETED';
    } else if (item.hasWarning) {
      statusColor = PdfColors.orange;
      statusText = 'WARNING';
    } else {
      statusColor = PdfColors.grey;
      statusText = 'PENDING';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with index and status
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: statusColor == PdfColors.green
                  ? PdfColors.green100
                  : statusColor == PdfColors.orange
                      ? PdfColors.orange100
                      : PdfColors.grey200,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
              border: pw.Border.all(color: statusColor),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Item #$index',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: statusColor,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    statusText,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Item details
          _buildDetailRow('Title:', item.title),
          _buildDetailRow('Description:', item.description),
          _buildDetailRow('Commands:', item.commands.join(', ')),

          if (item.isCompleted && item.completedAt != null) ...[
            pw.SizedBox(height: 8),
            _buildDetailRow(
              'Completed At:',
              DateFormat('MMMM dd, yyyy at hh:mm a').format(item.completedAt!),
              PdfColors.green,
            ),
          ],

          if (item.hasWarning && item.warningAt != null) ...[
            pw.SizedBox(height: 8),
            _buildDetailRow(
              'Warning At:',
              DateFormat('MMMM dd, yyyy at hh:mm a').format(item.warningAt!),
              PdfColors.orange,
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value,
      [PdfColor? valueColor]) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: valueColor ?? PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

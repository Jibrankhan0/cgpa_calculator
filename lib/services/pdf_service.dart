import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/course.dart';
import '../models/semester.dart';
import '../services/gpa_service.dart';

class PdfService {
  static Future<void> generateMarksSheet({
    required List<Semester> semesters,
    required String overallCGPA,
  }) async {
    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.interRegular(),
      bold: await PdfGoogleFonts.interBold(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: theme,
        header: (context) => _buildHeader(overallCGPA),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          ...semesters.map((semester) => _buildSemesterSection(semester)),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Marks Sheet - MCKRU',
    );
  }

  static pw.Widget _buildHeader(String overallCGPA) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MCKRU',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#6366F1'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Marks Sheet',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColor.fromHex('#64748B'),
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6366F1'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'CGPA: $overallCGPA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1),
        ],
      ),
    );
  }

  static pw.Widget _buildSemesterSection(Semester semester) {
    final gpa = _calculateSemesterGpa(semester);
    final totalCredits = _calculateTotalCredits(semester);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Semester Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F1F5F9'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  semester.name,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1E293B'),
                  ),
                ),
                pw.Text(
                  'GPA: ${gpa.toStringAsFixed(2)}  |  Credits: ${totalCredits.toStringAsFixed(1)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromHex('#6366F1'),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          // Course Table
          if (semester.courses.isEmpty)
            pw.Text(
              'No courses added',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('#94A3B8'),
                fontStyle: pw.FontStyle.italic,
              ),
            )
          else
            _buildCourseTable(semester.courses),
          pw.SizedBox(height: 12),
        ],
      ),
    );
  }

  static pw.Widget _buildCourseTable(List<Course> courses) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#64748B'),
      ),
      cellStyle: pw.TextStyle(
        fontSize: 10,
        color: PdfColor.fromHex('#1E293B'),
      ),
      cellAlignment: pw.Alignment.center,
      headerAlignment: pw.Alignment.center,
      headerDecoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromHex('#CBD5E1'),
            width: 1,
          ),
        ),
      ),
      headers: ['Course', 'Cr.', 'Mid', 'Final', 'Sessional', 'Total', 'Grade'],
      data: courses.map((course) {
        return [
          course.name.isEmpty ? '-' : course.name,
          course.creditHours.toStringAsFixed(0),
          course.midMarks.toStringAsFixed(0),
          course.finalMarks.toStringAsFixed(0),
          course.sessionalMarks.toStringAsFixed(0),
          course.totalMarks.toStringAsFixed(0),
          course.grade,
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1),
      },
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by GPA Calculator - MCKRU',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#94A3B8'),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#94A3B8'),
            ),
          ),
        ],
      ),
    );
  }

  static double _calculateSemesterGpa(Semester semester) {
    double credits = 0;
    double points = 0;
    for (final course in semester.courses) {
      final p = GpaService.getPoints(course.grade);
      points += p * course.creditHours;
      credits += course.creditHours;
    }
    return credits > 0 ? points / credits : 0.0;
  }

  static double _calculateTotalCredits(Semester semester) {
    double credits = 0;
    for (final course in semester.courses) {
      credits += course.creditHours;
    }
    return credits;
  }
}

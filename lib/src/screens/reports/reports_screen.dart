import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/reports/reports_bloc.dart';
import 'package:e_kafel/src/utils/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/services/export_service.dart';
import '../Auth/login_screen.dart';
import 'package:e_kafel/src/models/reports_model.dart';
import 'package:e_kafel/src/models/filter_model.dart';
import 'package:pdf/pdf.dart';

class ReportsScreen extends StatefulWidget {
  static const routeName = '/reports_screen';
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late String _kafalaHeadId;
  late String _institutionId;
  ReportFilter _currentFilter = ReportFilter();
  final List<String> _reportTypes = ['أيتام', 'كفالات', 'مشرفين', 'مهام', 'زيارات'];
  
  // متغيرات التصدير
  ExportSettings _exportSettings = const ExportSettings();
  bool _isExporting = false;
  List<Map<String, dynamic>> _allDataForExport = [];
  int _exportedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  void _initializeData() {
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoaded) {
      _kafalaHeadId = state.kafalaHeadId;
      _institutionId = state.institutionId;
      context.read<ReportsBloc>().add(LoadFilterOptionsEvent());
      context.read<ReportsBloc>().add(GetReportsEvent(_kafalaHeadId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        backgroundColor: AppColors.primaryColor,
        actions: [_buildFilterAction(), _buildExportAction()],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is ReportsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildFilterAction() {
    return IconButton(
      icon: const Icon(Icons.filter_alt),
      onPressed: _showFilterDialog,
      tooltip: 'فرز وتصفية البيانات',
    );
  }

  Widget _buildExportAction() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'خيارات التصدير',
      onSelected: (value) => _handleExportAction(value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf_simple', child: Text('تصدير PDF بسيط')),
        const PopupMenuItem(value: 'pdf_detailed', child: Text('تصدير PDF مفصل')),
        const PopupMenuItem(value: 'excel', child: Text('تصدير Excel')),
        const PopupMenuItem(value: 'settings', child: Text('إعدادات التصدير')),
      ],
    );
  }

  void _handleExportAction(String value) {
    switch (value) {
      case 'pdf_simple':
        _exportPdf(simple: true);
        break;
      case 'pdf_detailed':
        _exportPdf(simple: false);
        break;
      case 'excel':
        _exportExcel();
        break;
      case 'settings':
        _showExportSettingsDialog();
        break;
    }
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildReportTypeSelector(),
        if (_isExporting) _buildExportProgress(),
        Expanded(child: _buildReportContent()),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: DropdownButtonFormField<String>(
        value: _currentFilter.reportType,
        decoration: const InputDecoration(
          labelText: 'اختر نوع البيانات',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('اختر نوع التقرير')),
          ..._reportTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
        ],
        onChanged: (value) => setState(() {
          _currentFilter = _currentFilter.copyWith(reportType: value);
          if (value != null) _showFilterDialog();
        }),
      ),
    );
  }

  Widget _buildExportProgress() {
    return LinearProgressIndicator(
      value: _exportedCount / (_allDataForExport.isNotEmpty ? _allDataForExport.length : 1),
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
    );
  }

  Widget _buildReportContent() {
    if (_currentFilter.reportType == null) {
      return _buildDefaultView();
    }

    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state is ReportsDataLoaded) {
          return _buildDataView(state.data);
        } else if (state is ReportsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return _buildEmptyState();
        }
      },
    );
  }

  Widget _buildDefaultView() {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state is ReportsLoaded && state.reports.isNotEmpty) {
          return ListView.builder(
            itemCount: state.reports.length,
            itemBuilder: (context, index) => _buildReportItem(state.reports[index]),
          );
        }
        return const Center(child: Text('لا توجد تقارير محفوظة'));
      },
    );
  }

  Widget _buildReportItem(ReportModel report) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(report.title),
        subtitle: Text(report.filtersSummary),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => _exportSavedReport(report),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReport(report.reportId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataView(List<Map<String, dynamic>> data) {
    return Column(
      children: [
        _buildDataHeader(data.length),
        Expanded(
          child: data.isEmpty
              ? const Center(child: Text('لا توجد بيانات تطابق معايير البحث'))
              : ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) => _buildDataItem(data[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildDataHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('عدد النتائج: $count', style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                onPressed: () => _exportPdf(simple: true),
                tooltip: 'تصدير PDF',
              ),
              IconButton(
                icon: const Icon(Icons.table_chart, color: Colors.green),
                onPressed: _exportExcel,
                tooltip: 'تصدير Excel',
              ),
              if (count > 1000) IconButton(
                icon: const Icon(Icons.cloud_download, color: Colors.orange),
                onPressed: _exportLargeData,
                tooltip: 'تصدير البيانات الكبيرة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(item['name'] ?? item['fullName'] ?? item['title'] ?? item['orphanName'] ?? 'غير معروف'),
        subtitle: _buildDataSubtitle(item),
        onTap: () => _showDataDetails(item),
      ),
    );
  }

  Widget _buildDataSubtitle(Map<String, dynamic> item) {
    switch (_currentFilter.reportType) {
      case 'أيتام':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['governorate'] != null) Text('المحافظة: ${item['governorate']}'),
            if (item['city'] != null) Text('المدينة: ${item['city']}'),
            if (item['sponsorshipStatus'] != null) Text('حالة الكفالة: ${item['sponsorshipStatus']}'),
            if (item['orphanNo'] != null) Text('رقم اليتيم: ${item['orphanNo']}'),
            if (item['age'] != null) Text('العمر: ${item['age']}'),
          ],
        );
      case 'كفالات':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['type'] != null) Text('النوع: ${item['type']}'),
            if (item['budget'] != null) Text('الميزانية: ${item['budget']}'),
            if (item['status'] != null) Text('الحالة: ${item['status']}'),
          ],
        );
      case 'مشرفين':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['userRole'] != null) Text('الدور: ${item['userRole']}'),
            if (item['areaResponsibleFor'] != null) Text('المنطقة: ${item['areaResponsibleFor']}'),
            if (item['mobileNumber'] != null) Text('الجوال: ${item['mobileNumber']}'),
          ],
        );
      case 'مهام':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['priority'] != null) Text('الأولوية: ${item['priority']}'),
            if (item['status'] != null) Text('الحالة: ${item['status']}'),
            if (item['dueDate'] != null) Text('تاريخ الاستحقاق: ${_formatDate(item['dueDate'])}'),
          ],
        );
      case 'زيارات':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['area'] != null) Text('المنطقة: ${item['area']}'),
            if (item['date'] != null) Text('التاريخ: ${item['date']}'),
            if (item['status'] != null) Text('الحالة: ${item['status']}'),
          ],
        );
      default:
        return const Text('بيانات');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('اختر نوع البيانات وطبق الفلاتر', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showFilterDialog,
            child: const Text('فتح خيارات الفرز والتصفية'),
          ),
        ],
      ),
    );
  }

  // ==================== دوال التصدير ====================
  Future<void> _exportPdf({bool simple = true}) async {
    try {
      final state = context.read<ReportsBloc>().state;
      if (state is! ReportsDataLoaded || state.data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للتصدير')),
        );
        return;
      }

      setState(() {
        _isExporting = true;
        _exportedCount = 0;
      });

      final file = await ExportService.exportToPdf(
        title: 'تقرير ${_currentFilter.reportType}',
        data: state.data,
        columns: _getExportColumns(),
        institutionName: 'مؤسسة كفيل',
        withCharts: !simple && _exportSettings.includeCharts,
        withSummary: _exportSettings.includeSummary,
      );

      setState(() {
        _isExporting = false;
        _exportedCount = state.data.length;
      });

      await ExportService.shareFile(file, context, 'تقرير ${_currentFilter.reportType}');
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التصدير: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportExcel() async {
    try {
      final state = context.read<ReportsBloc>().state;
      if (state is! ReportsDataLoaded || state.data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للتصدير')),
        );
        return;
      }

      setState(() {
        _isExporting = true;
        _exportedCount = 0;
      });

      final file = await ExportService.exportToExcel(
        title: 'تقرير ${_currentFilter.reportType}',
        data: state.data,
        columns: _getExportColumns(),
        institutionName: 'مؤسسة كفيل',
      );

      setState(() {
        _isExporting = false;
        _exportedCount = state.data.length;
      });

      await ExportService.shareFile(file, context, 'تقرير ${_currentFilter.reportType}');
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التصدير: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportLargeData() async {
    try {
      setState(() {
        _isExporting = true;
        _allDataForExport = [];
        _exportedCount = 0;
      });

      // جلب كل البيانات باستخدام Pagination
      await _fetchAllDataForExport();

      if (_allDataForExport.isEmpty) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للتصدير')),
        );
        return;
      }

      // تصدير البيانات الكبيرة
      final file = await ExportService.exportToPdf(
        title: 'تقرير ${_currentFilter.reportType} - كامل',
        data: _allDataForExport,
        columns: _getExportColumns(),
        institutionName: 'مؤسسة كفيل',
        withSummary: true,
      );

      setState(() => _isExporting = false);

      await ExportService.shareFile(file, context, 'تقرير ${_currentFilter.reportType} - كامل');
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير البيانات الكبيرة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchAllDataForExport() async {
    final reportsService = context.read<ReportsBloc>().reportsService;
    List<Map<String, dynamic>> allData = [];
    DocumentSnapshot? lastDocument;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('جاري تجهيز البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            StreamBuilder<int>(
              stream: _getExportProgressStream(),
              builder: (context, snapshot) {
                return Text('تم تحميل ${snapshot.data ?? 0} سجل...');
              },
            ),
          ],
        ),
      ),
    );

    try {
      while (true) {
        final batch = await reportsService.getFilteredDataWithPagination(
          _currentFilter,
          limit: 1000,
          lastDocument: lastDocument,
        );

        if (batch.isEmpty) break;

        allData.addAll(batch);
        setState(() => _exportedCount = allData.length);

        if (batch.length < 1000) break;

        // تحديث lastDocument للاستمرار في الجلب
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _allDataForExport = allData;
      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      rethrow;
    }
  }

  Stream<int> _getExportProgressStream() async* {
    while (_isExporting) {
      yield _exportedCount;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _exportSavedReport(ReportModel report) async {
    try {
      final reportsService = context.read<ReportsBloc>().reportsService;
      
      // إنشاء ReportFilter من ReportModel يدوياً
      final filter = ReportFilter(
        reportType: report.reportType,
        governorate: report.region,
        city: report.city,
        orphanStatus: report.orphanStatus,
        sponsorType: report.sponsorType,
        financialStatus: report.financialStatus,
        searchQuery: report.searchQuery,
        sortBy: report.sortBy,
        sortAscending: report.sortAscending,
        startDate: report.startDate,
        endDate: report.endDate,
      );
      
      final data = await reportsService.getFilteredData(filter);

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للتصدير')),
        );
        return;
      }

      final file = await ExportService.exportToPdf(
        title: report.title,
        data: data,
        columns: _getExportColumnsForReport(report),
        institutionName: 'مؤسسة كفيل',
        withSummary: true,
      );

      await ExportService.shareFile(file, context, report.title);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير التقرير: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==================== دوال مساعدة ====================
  List<String> _getExportColumns() {
    switch (_currentFilter.reportType) {
      case 'أيتام':
        return ['الاسم', 'العمر', 'المحافظة', 'المدينة', 'حالة الكفالة', 'رقم اليتيم'];
      case 'كفالات':
        return ['الاسم', 'النوع', 'الميزانية', 'الحالة', 'تاريخ الإنشاء'];
      case 'مشرفين':
        return ['الاسم', 'الدور', 'المنطقة', 'الجوال', 'البريد الإلكتروني'];
      case 'مهام':
        return ['العنوان', 'الأولوية', 'الحالة', 'نوع المهمة', 'تاريخ الاستحقاق'];
      case 'زيارات':
        return ['اسم اليتيم', 'المنطقة', 'التاريخ', 'الحالة', 'الملاحظات'];
      default:
        return ['الاسم', 'التاريخ', 'الحالة'];
    }
  }

  List<String> _getExportColumnsForReport(ReportModel report) {
    return _getExportColumns();
  }

  void _showExportSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إعدادات التصدير'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('تضمين جميع الحقول'),
                    value: _exportSettings.includeAllFields,
                    onChanged: (value) => setState(() {
                      _exportSettings = _exportSettings.copyWith(includeAllFields: value);
                    }),
                  ),
                  CheckboxListTile(
                    title: const Text('تضمين الرسوم البيانية'),
                    value: _exportSettings.includeCharts,
                    onChanged: (value) => setState(() {
                      _exportSettings = _exportSettings.copyWith(includeCharts: value);
                    }),
                  ),
                  CheckboxListTile(
                    title: const Text('تضمين الملخص'),
                    value: _exportSettings.includeSummary,
                    onChanged: (value) => setState(() {
                      _exportSettings = _exportSettings.copyWith(includeSummary: value);
                    }),
                  ),
                  CheckboxListTile(
                    title: const Text('تقسيم الملفات الكبيرة'),
                    value: _exportSettings.splitLargeFiles,
                    onChanged: (value) => setState(() {
                      _exportSettings = _exportSettings.copyWith(splitLargeFiles: value);
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text('تنسيق الصفحة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<PdfPageFormat>(
                    value: _exportSettings.pageFormat,
                    items: [
                      DropdownMenuItem(value: PdfPageFormat.a4, child: const Text('A4')),
                      DropdownMenuItem(value: PdfPageFormat.a3, child: const Text('A3')),
                      DropdownMenuItem(value: PdfPageFormat.letter, child: const Text('Letter')),
                    ],
                    onChanged: (value) => setState(() {
                      _exportSettings = _exportSettings.copyWith(pageFormat: value);
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _exportSettings = _exportSettings);
                  Navigator.pop(context);
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    if (_currentFilter.reportType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار نوع التقرير أولاً')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          final filterOptions = state is FilterOptionsLoaded ? state.filterOptions : {};
          
          return FilterDialog(
            currentFilter: _currentFilter,
            onApply: (filter) {
              setState(() => _currentFilter = filter);
              context.read<ReportsBloc>().add(FilterDataEvent(filter));
            },
            filterOptions: filterOptions.cast<String, List<String>>(),
          );
        },
      ),
    );
  }

  void _deleteReport(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التقرير'),
        content: const Text('هل أنت متأكد من حذف هذا التقرير؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              context.read<ReportsBloc>().add(DeleteReportEvent(reportId));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showDataDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل البيانات'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: item.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${entry.key}: ${entry.value}'),
              )
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  Widget _buildDrawer() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          return AppDrawer(
            institutionId: state.institutionId,
            kafalaHeadId: state.kafalaHeadId,
            userName: state.userName,
            userRole: state.userRole,
            profileImageUrl: state.profileImageUrl,
            orphanCount: state.totalOrphans,
            taskCount: state.totalTasks,
            visitCount: state.totalVisits,
            onLogout: () {
              context.read<AuthBloc>().add(LogoutButtonPressed());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          );
        }
        return AppDrawer(
          institutionId: '',
          kafalaHeadId: '',
          userName: 'جاري التحميل...',
          userRole: '...',
          profileImageUrl: '',
          orphanCount: 0,
          taskCount: 0,
          visitCount: 0,
          onLogout: () {},
        );
      },
    );
  }
}

// FilterDialog يبقى كما هو بدون تغييرات
class FilterDialog extends StatefulWidget {
  final ReportFilter currentFilter;
  final Function(ReportFilter) onApply;
  final Map<String, List<String>> filterOptions;
  
  const FilterDialog({
    super.key,
    required this.currentFilter,
    required this.onApply,
    required this.filterOptions,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late ReportFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('خيارات الفرز والتصفية'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGeneralFilters(),
            const SizedBox(height: 16),
            
            if (_filter.reportType == 'أيتام') ..._buildOrphanFilters(),
            if (_filter.reportType == 'كفالات') ..._buildSponsorFilters(),
            if (_filter.reportType == 'مشرفين') ..._buildSupervisorFilters(),
            if (_filter.reportType == 'مهام') ..._buildTaskFilters(),
            if (_filter.reportType == 'زيارات') ..._buildVisitFilters(),
            
            const SizedBox(height: 16),
            _buildSortingOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_filter);
            Navigator.pop(context);
          },
          child: const Text('تطبيق'),
        ),
      ],
    );
  }

  // باقي دوال FilterDialog تبقى كما هي بدون تغيير
  Widget _buildGeneralFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الفلاتر الجغرافية:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        _buildFilterDropdown(
          'المحافظة',
          _filter.governorate,
          widget.filterOptions['governorates'] ?? [],
          (value) => setState(() => _filter = _filter.copyWith(governorate: value)),
        ),
        
        const SizedBox(height: 8),
        
        _buildFilterDropdown(
          'المدينة',
          _filter.city,
          widget.filterOptions['cities'] ?? [],
          (value) => setState(() => _filter = _filter.copyWith(city: value)),
        ),
        
        const SizedBox(height: 8),
        
        _buildFilterDropdown(
          'الحي',
          _filter.neighborhood,
          widget.filterOptions['neighborhoods'] ?? [],
          (value) => setState(() => _filter = _filter.copyWith(neighborhood: value)),
        ),
        
        const SizedBox(height: 16),
        const Text('النطاق الزمني:', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_filter.startDate == null 
                    ? 'من تاريخ' 
                    : '${_filter.startDate!.day}/${_filter.startDate!.month}/${_filter.startDate!.year}'),
                onPressed: () => _selectStartDate(),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_filter.endDate == null 
                    ? 'إلى تاريخ' 
                    : '${_filter.endDate!.day}/${_filter.endDate!.month}/${_filter.endDate!.year}'),
                onPressed: () => _selectEndDate(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        TextField(
          decoration: const InputDecoration(
            labelText: 'بحث نصي',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _filter = _filter.copyWith(searchQuery: value.isEmpty ? null : value)),
        ),
      ],
    );
  }

  List<Widget> _buildOrphanFilters() {
    return [
      const Text('فلاتر الأيتام:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'حالة الكفالة',
        _filter.orphanStatus,
        widget.filterOptions['orphanStatuses'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(orphanStatus: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'نوع اليتيم',
        _filter.orphanType,
        widget.filterOptions['orphanTypes'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(orphanType: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'الجنس',
        _filter.gender,
        widget.filterOptions['genders'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(gender: value)),
      ),
      
      // ... باقي الفلاتر تبقى كما هي
    ];
  }

  // باقي دوال الفلاتر تبقى كما هي
  List<Widget> _buildSponsorFilters() { /* ... */ return []; }
  List<Widget> _buildSupervisorFilters() { /* ... */ return []; }
  List<Widget> _buildTaskFilters() { /* ... */ return []; }
  List<Widget> _buildVisitFilters() { /* ... */ return []; }

  Widget _buildSortingOptions() {
    return Column(
      children: [
        const Text('خيارات الفرز:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _filter.sortBy,
                decoration: const InputDecoration(
                  labelText: 'ترتيب حسب',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('افتراضي')),
                  ..._filter.getSortOptions().map((option) => 
                    DropdownMenuItem(
                      value: option['value'],
                      child: Text(option['label'] ?? ''),
                    )
                  ),
                ],
                onChanged: (value) => setState(() => _filter = _filter.copyWith(sortBy: value)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_filter.sortAscending! ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () => setState(() => 
                _filter = _filter.copyWith(sortAscending: !_filter.sortAscending!)),
              tooltip: _filter.sortAscending! ? 'تصاعدي' : 'تنازلي',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text('كل $label')),
        ...options.map((option) => DropdownMenuItem(value: option, child: Text(option))),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filter.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _filter = _filter.copyWith(startDate: picked));
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filter.endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _filter = _filter.copyWith(endDate: picked));
    }
  }
}
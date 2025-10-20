import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/reports/reports_bloc.dart';
import 'package:e_kafel/src/utils/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import '../Auth/login_screen.dart';
import 'package:e_kafel/src/models/reports_model.dart';
import 'package:e_kafel/src/models/filter_model.dart';

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
        actions: [_buildFilterAction()],
      ),
      drawer: _buildDrawer(),
      body: BlocListener<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is FilterOptionsLoaded) {}
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

  Widget _buildContent() {
    return Column(
      children: [
        _buildReportTypeSelector(),
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
              onPressed: () => _exportReport(report),
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
                onPressed: () => _exportFilteredData(),
              ),
              IconButton(
                icon: const Icon(Icons.table_chart, color: Colors.green),
                onPressed: () => _exportFilteredExcel(),
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

  void _exportReport(ReportModel report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('سيتم تصدير ${report.title}')),
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

  void _exportFilteredData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تصدير البيانات إلى PDF...')),
    );
  }

  void _exportFilteredExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تصدير البيانات إلى Excel...')),
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
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'الحالة التعليمية',
        _filter.educationStatus,
        widget.filterOptions['educationStatuses'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(educationStatus: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'المستوى التعليمي',
        _filter.educationLevel,
        widget.filterOptions['educationLevels'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(educationLevel: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'الحالة الصحية',
        _filter.healthCondition,
        widget.filterOptions['healthConditions'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(healthCondition: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'حالة السكن',
        _filter.housingCondition,
        widget.filterOptions['housingConditions'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(housingCondition: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'ملكية السكن',
        _filter.housingOwnership,
        widget.filterOptions['housingOwnerships'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(housingOwnership: value)),
      ),
      
      const SizedBox(height: 16),
      const Text('الفلاتر الرقمية:', style: TextStyle(fontWeight: FontWeight.bold)),
      
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'من رقم اليتيم',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final num = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(minOrphanNo: num));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'إلى رقم اليتيم',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final num = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(maxOrphanNo: num));
              },
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 8),
      
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'من رقم الهوية',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final num = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(minOrphanIdNumber: num));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'إلى رقم الهوية',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final num = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(maxOrphanIdNumber: num));
              },
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 8),
      
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'من العمر',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final age = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(minAge: age));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'إلى العمر',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final age = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(maxAge: age));
              },
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 8),
      
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'من عدد الأفراد',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final num = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(minFamilyMembers: num));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'إلى عدد الأفراد',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final num = int.tryParse(value);
                setState(() => _filter = _filter.copyWith(maxFamilyMembers: num));
              },
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSponsorFilters() {
    return [
      const Text('فلاتر الكفالات:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'نوع الكفالة',
        _filter.sponsorType,
        widget.filterOptions['sponsorTypes'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(sponsorType: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'الحالة المالية',
        _filter.financialStatus,
        widget.filterOptions['financialStatuses'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(financialStatus: value)),
      ),
      
      const SizedBox(height: 16),
      const Text('نطاقات مالية:', style: TextStyle(fontWeight: FontWeight.bold)),
      
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'أقل ميزانية',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                setState(() => _filter = _filter.copyWith(minBudget: amount));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'أعلى ميزانية',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                setState(() => _filter = _filter.copyWith(maxBudget: amount));
              },
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 8),
      
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'أقل مصروفات',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                setState(() => _filter = _filter.copyWith(minSpent: amount));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'أعلى مصروفات',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                setState(() => _filter = _filter.copyWith(maxSpent: amount));
              },
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSupervisorFilters() {
    return [
      const Text('فلاتر المشرفين:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'الدور',
        _filter.userRole,
        widget.filterOptions['userRoles'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(userRole: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'المنطقة المسؤولة',
        _filter.areaResponsibleFor,
        widget.filterOptions['areas'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(areaResponsibleFor: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'السكن الوظيفي',
        _filter.functionalLodgment,
        widget.filterOptions['functionalLodgments'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(functionalLodgment: value)),
      ),
    ];
  }

  List<Widget> _buildTaskFilters() {
    return [
      const Text('فلاتر المهام:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'الأولوية',
        _filter.taskPriority,
        widget.filterOptions['taskPriorities'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(taskPriority: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'الحالة',
        _filter.taskStatus,
        widget.filterOptions['taskStatuses'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(taskStatus: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'نوع المهمة',
        _filter.taskType,
        widget.filterOptions['taskTypes'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(taskType: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'موقع المهمة',
        _filter.taskLocation,
        widget.filterOptions['taskLocations'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(taskLocation: value)),
      ),
    ];
  }

  List<Widget> _buildVisitFilters() {
    return [
      const Text('فلاتر الزيارات:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'المنطقة',
        _filter.visitArea,
        widget.filterOptions['visitAreas'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(visitArea: value)),
      ),
      
      const SizedBox(height: 8),
      
      _buildFilterDropdown(
        'حالة الزيارة',
        _filter.visitStatus,
        widget.filterOptions['visitStatuses'] ?? [],
        (value) => setState(() => _filter = _filter.copyWith(visitStatus: value)),
      ),
    ];
  }

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
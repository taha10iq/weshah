// lib/presentation/screens/customers/customers_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/loading_widget.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(customerSearchProvider);
    final customersAsync = ref.watch(customersListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('العملاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(customersListProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/new'),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'عميل جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerSearchProvider.notifier).clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (v) =>
                  ref.read(customerSearchProvider.notifier).setQuery(v),
              style: GoogleFonts.cairo(),
            ),
          ),
          // List
          Expanded(
            child: customersAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ShimmerCard(),
                ),
              ),
              error: (e, _) => ErrorWidget2(
                message: e.toString(),
                onRetry: () => ref.invalidate(customersListProvider),
              ),
              data: (customers) => customers.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.people_outline_rounded,
                      title: search.isNotEmpty
                          ? 'لا توجد نتائج للبحث'
                          : 'لا يوجد عملاء بعد',
                      subtitle: search.isNotEmpty
                          ? 'جرب كلمة بحث مختلفة'
                          : 'أضف أول عميل بالضغط على الزر أدناه',
                      action: search.isEmpty
                          ? ElevatedButton.icon(
                              onPressed: () => context.go('/customers/new'),
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('إضافة عميل'),
                            )
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) =>
                          _CustomerCard(customer: customers[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            radius: 24,
            child: Text(
              customer.fullName.isNotEmpty ? customer.fullName[0] : '?',
              style: GoogleFonts.cairo(
                color: AppTheme.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            customer.fullName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    customer.phone,
                    style: GoogleFonts.cairo(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (customer.address != null && customer.address!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.address!,
                        style: GoogleFonts.cairo(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.arrow_back_ios_rounded, size: 16),
          onTap: () => context.go('/customers/${customer.id}'),
        ),
      ),
    );
  }
}

// import 'package:flutter/cupertino.dart';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:personal_finance/helper/app_formater.dart';
// import 'package:personal_finance/controllers/asset_provider.dart';
// import 'package:personal_finance/controllers/emi_provider.dart';
// import 'package:personal_finance/views/manage_assets_screen.dart';
// import 'package:personal_finance/controllers/net_worth_provider.dart';
// import 'package:personal_finance/controllers/shared_preferences_provider.dart';
// import 'package:personal_finance/models/asset_model.dart'; // Import Asset model

// class NetWorthScreen extends ConsumerWidget {
//   const NetWorthScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 32), // Top spacing
//             Row(
//               children: [
//                 CupertinoNavigationBarBackButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//                 Text(
//                   'Net Worth',
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).colorScheme.onSurface,
//                       ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 32),
//             const _MainNetWorthCard(),
//             const SizedBox(height: 24),
//             const _AssetsCard(),
//             const SizedBox(height: 24),
//             const _LiabilitiesCard(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// A large card displaying the main net worth figure.
// class _MainNetWorthCard extends ConsumerWidget {
//   const _MainNetWorthCard();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final netWorthAsync = ref.watch(netWorthProvider);
//     final changeAsync = ref.watch(netWorthChangeProvider);
//     final currency = ref.watch(currencyProvider);

//     return netWorthAsync.when(
//       data: (netWorth) => Container(
//         padding: const EdgeInsets.all(24.0),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surface,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//               color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
//           boxShadow: [
//             BoxShadow(
//               color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Text('Total Net Worth',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).colorScheme.onSurface,
//                     )),
//             const SizedBox(height: 8),
//             Text(AppFormatters.formatCurrency(netWorth, currency),
//                 style: Theme.of(context).textTheme.displayMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).colorScheme.onSurface,
//                     )),
//             const SizedBox(height: 8),
//             changeAsync.when(
//               data: (change) => Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(change >= 0 ? Icons.trending_up : Icons.trending_down,
//                       color: change >= 0
//                           ? Theme.of(context).colorScheme.primary
//                           : Theme.of(context).colorScheme.error,
//                       size: 16),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${change >= 0 ? '+' : ''}${AppFormatters.formatCurrency(change, currency)} this month',
//                     style: TextStyle(
//                         color: change >= 0
//                             ? Theme.of(context).colorScheme.primary
//                             : Theme.of(context).colorScheme.error),
//                   ),
//                 ],
//               ),
//               loading: () => const SizedBox(),
//               error: (e, s) => const SizedBox(),
//             )
//           ],
//         ),
//       ),
//       loading: () => Container(
//         height: 200,
//         padding: const EdgeInsets.all(24.0),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surface,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//               color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
//           boxShadow: [
//             BoxShadow(
//               color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: const Center(child: CircularProgressIndicator()),
//       ),
//       error: (e, s) => Container(
//         height: 200,
//         padding: const EdgeInsets.all(24.0),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surface,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//               color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
//           boxShadow: [
//             BoxShadow(
//               color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Center(
//             child: Text(
//           'Error: $e',
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                 color: Theme.of(context).colorScheme.error,
//               ),
//         )),
//       ),
//     );
//   }
// }

// // Helper function to get IconData from string
// IconData _getIconData(String? iconName) {
//   if (iconName == null) return Icons.category; // Default fallback icon

//   // A simple mapping for common icons. This can be extended.
//   switch (iconName) {
//     case 'wallet':
//       return Icons.wallet;
//     case 'savings':
//       return Icons.savings;
//     case 'attach_money':
//       return Icons.attach_money;
//     case 'account_balance':
//       return Icons.account_balance;
//     case 'home_outlined': // For liabilities
//       return Icons.home_outlined;
//     default:
//       return Icons.category; // Generic fallback
//   }
// }

// /// A card listing all asset accounts.
// class _AssetsCard extends ConsumerWidget {
//   const _AssetsCard();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final assetsAsync = ref.watch(assetListProvider);
//     final totalAssetsAsync = ref.watch(totalAssetsProvider);
//     final currency = ref.watch(currencyProvider);

//     return Container(
//       padding: const EdgeInsets.all(20.0),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//             color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
//         boxShadow: [
//           BoxShadow(
//             color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('Assets',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).colorScheme.onSurface,
//                       )),
//               TextButton(
//                 onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const ManageAssetsScreen())),
//                 style: TextButton.styleFrom(
//                   foregroundColor: Theme.of(context).colorScheme.primary,
//                   textStyle: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 child: const Text('Manage'),
//               )
//             ],
//           ),
//           const SizedBox(height: 16),
//           assetsAsync.when(
//             data: (assets) => Column(
//               children: assets.isEmpty
//                   ? [
//                       Text('No assets added.',
//                           style:
//                               Theme.of(context).textTheme.bodyMedium?.copyWith(
//                                     color: Theme.of(context)
//                                         .colorScheme
//                                         .onSurfaceVariant,
//                                   ))
//                     ]
//                   : assets
//                       .map((asset) => Padding(
//                             padding: const EdgeInsets.only(bottom: 12.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Icon(
//                                         _getIconData(
//                                             asset.icon), // Use dynamic icon
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .onSurfaceVariant,
//                                         size: 20),
//                                     const SizedBox(width: 8),
//                                     Text(asset.name,
//                                         style: Theme.of(context)
//                                             .textTheme
//                                             .bodyMedium
//                                             ?.copyWith(
//                                               color: Theme.of(context)
//                                                   .colorScheme
//                                                   .onSurface,
//                                             )),
//                                   ],
//                                 ),
//                                 Text(
//                                     AppFormatters.formatCurrency(
//                                         asset.value, currency),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodyMedium
//                                         ?.copyWith(
//                                           fontWeight: FontWeight.bold,
//                                           color: Theme.of(context)
//                                               .colorScheme
//                                               .onSurface,
//                                         )),
//                               ],
//                             ),
//                           ))
//                       .toList(),
//             ),
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (e, s) => Center(
//                 child: Text('Error: $e',
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                           color: Theme.of(context).colorScheme.error,
//                         ))),
//           ),
//           const SizedBox(height: 16),
//           totalAssetsAsync.when(
//             data: (total) => Column(
//               children: [
//                 Divider(
//                     height: 1,
//                     color:
//                         Theme.of(context).colorScheme.outline.withOpacity(0.2)),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 12.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text('Total Assets',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyMedium
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).colorScheme.onSurface,
//                               )),
//                       Text(AppFormatters.formatCurrency(total, currency),
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyMedium
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).colorScheme.onSurface,
//                               )),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             loading: () => const SizedBox(),
//             error: (e, s) => const SizedBox(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// A card listing all liability accounts.
// class _LiabilitiesCard extends ConsumerWidget {
//   const _LiabilitiesCard();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final emisAsync = ref.watch(emiListProvider);
//     final totalLiabilitiesAsync = ref.watch(totalLiabilitiesProvider);
//     final currency = ref.watch(currencyProvider);

//     return Container(
//       padding: const EdgeInsets.all(20.0),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//             color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
//         boxShadow: [
//           BoxShadow(
//             color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Liabilities (Loans)',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: Theme.of(context).colorScheme.onSurface,
//                   )),
//           const SizedBox(height: 16),
//           emisAsync.when(
//             data: (emis) {
//               final activeEmis =
//                   emis.where((e) => e.tenureRemainingMonths > 0).toList();
//               return Column(
//                 children: activeEmis.isEmpty
//                     ? [
//                         Text('No active loans.',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .bodyMedium
//                                 ?.copyWith(
//                                   color: Theme.of(context)
//                                       .colorScheme
//                                       .onSurfaceVariant,
//                                 ))
//                       ]
//                     : activeEmis.map((emi) {
//                         double totalLiability;
//                         if (emi.isCompoundInterest &&
//                             emi.interestRate != null &&
//                             emi.interestRate! > 0) {
//                           // Calculate Present Value (outstanding principal) for compound interest loans
//                           final monthlyRate = (emi.interestRate! / 100) / 12;
//                           final remainingTenure = emi.tenureRemainingMonths;
//                           final emiAmount = emi.monthlyEmiAmount;
//                           // PV = PMT * [1 - (1 + r)^-n] / r
//                           totalLiability = emiAmount *
//                               (1 - pow(1 + monthlyRate, -remainingTenure)) /
//                               monthlyRate;
//                         } else {
//                           // Use simple interest calculation or just remaining payments if no interest rate
//                           final remainingPrincipal =
//                               emi.monthlyEmiAmount * emi.tenureRemainingMonths;
//                           totalLiability = remainingPrincipal;
//                           if (emi.interestRate != null &&
//                               emi.interestRate! > 0) {
//                             final interest =
//                                 remainingPrincipal * (emi.interestRate! / 100);
//                             totalLiability += interest;
//                           }
//                         }

//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 12.0),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                       Icons
//                                           .home_outlined, // Using home icon for loans
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .onSurfaceVariant,
//                                       size: 20),
//                                   const SizedBox(width: 8),
//                                   Text(emi.loanName,
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .bodyMedium
//                                           ?.copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .onSurface,
//                                           )),
//                                 ],
//                               ),
//                               Text(
//                                   AppFormatters.formatCurrency(
//                                       totalLiability, currency),
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodyMedium
//                                       ?.copyWith(
//                                         fontWeight: FontWeight.bold,
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .onSurface,
//                                       )),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//               );
//             },
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (e, s) => Center(
//                 child: Text('Error: $e',
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                           color: Theme.of(context).colorScheme.error,
//                         ))),
//           ),
//           const SizedBox(height: 16),
//           totalLiabilitiesAsync.when(
//             data: (total) => Column(
//               children: [
//                 Divider(
//                     height: 1,
//                     color:
//                         Theme.of(context).colorScheme.outline.withOpacity(0.2)),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 12.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text('Total Liabilities',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyMedium
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).colorScheme.onSurface,
//                               )),
//                       Text(AppFormatters.formatCurrency(total, currency),
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyMedium
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).colorScheme.onSurface,
//                               )),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             loading: () => const SizedBox(),
//             error: (e, s) => const SizedBox(),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/views/manage_assets_screen.dart';
import 'package:personal_finance/controllers/net_worth_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
// import 'package:personal_finance/models/asset_model.dart'; // Not strictly needed if used via provider

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAmoled = ref.watch(isAmoledProvider); // Watch isAmoledProvider
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isAmoled ? Colors.black : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isAmoled ? Colors.black : theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Net Worth',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MainNetWorthCard(),
            SizedBox(height: 24),
            _AssetsCard(),
            SizedBox(height: 24),
            _LiabilitiesCard(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// A large card displaying the main net worth figure.
class _MainNetWorthCard extends ConsumerWidget {
  const _MainNetWorthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(netWorthProvider);
    final changeAsync = ref.watch(netWorthChangeProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return netWorthAsync.when(
      data: (netWorth) => Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text('Total Net Worth',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                )),
            const SizedBox(height: 12),
            Text(AppFormatters.formatCurrency(netWorth, currency),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 36,
                )),
            const SizedBox(height: 16),
            changeAsync.when(
              data: (change) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        change >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${change >= 0 ? '+' : ''}${AppFormatters.formatCurrency(change, currency)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(),
              error: (e, s) => const SizedBox(),
            )
          ],
        ),
      ),
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

// Helper function to get IconData
IconData _getIconData(String? iconName) {
  if (iconName == null) return Icons.category_rounded;
  switch (iconName) {
    case 'wallet':
      return Icons.account_balance_wallet_rounded;
    case 'savings':
      return Icons.savings_rounded;
    case 'attach_money':
      return Icons.attach_money_rounded;
    case 'account_balance':
      return Icons.account_balance_rounded;
    case 'home_outlined':
      return Icons.home_rounded;
    default:
      return Icons.category_rounded;
  }
}

/// A card listing all asset accounts.
class _AssetsCard extends ConsumerWidget {
  const _AssetsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);
    final totalAssetsAsync = ref.watch(totalAssetsProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        size: 20, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Text('Assets',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageAssetsScreen())),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Manage'),
              )
            ],
          ),
          const SizedBox(height: 20),

          // List
          assetsAsync.when(
            data: (assets) {
              if (assets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No assets added.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor)),
                  ),
                );
              }
              return Column(
                children: assets
                    .map((asset) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getIconData(asset.icon),
                                    color: theme.colorScheme.primary, size: 18),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(asset.name,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600)),
                              ),
                              Text(
                                AppFormatters.formatCurrency(
                                    asset.value, currency),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green, // Positive value
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),

          const Divider(height: 32),

          // Total Row
          totalAssetsAsync.when(
            data: (total) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Assets',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor, fontWeight: FontWeight.w500)),
                Text(AppFormatters.formatCurrency(total, currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    )),
              ],
            ),
            loading: () => const SizedBox(),
            error: (e, s) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

/// A card listing all liability accounts.
class _LiabilitiesCard extends ConsumerWidget {
  const _LiabilitiesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emisAsync = ref.watch(emiListProvider);
    final totalLiabilitiesAsync = ref.watch(totalLiabilitiesProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_downward_rounded,
                    size: 20, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Text('Liabilities (Loans)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 20),

          // List
          emisAsync.when(
            data: (emis) {
              final activeEmis =
                  emis.where((e) => e.tenureRemainingMonths > 0).toList();

              if (activeEmis.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No active loans.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor)),
                  ),
                );
              }

              return Column(
                children: activeEmis.map((emi) {
                  // Calculation Logic (Preserved)
                  double totalLiability;
                  if (emi.isCompoundInterest &&
                      emi.interestRate != null &&
                      emi.interestRate! > 0) {
                    final monthlyRate = (emi.interestRate! / 100) / 12;
                    final remainingTenure = emi.tenureRemainingMonths;
                    final emiAmount = emi.monthlyEmiAmount;
                    totalLiability = emiAmount *
                        (1 - pow(1 + monthlyRate, -remainingTenure)) /
                        monthlyRate;
                  } else {
                    final remainingPrincipal =
                        emi.monthlyEmiAmount * emi.tenureRemainingMonths;
                    totalLiability = remainingPrincipal;
                    if (emi.interestRate != null && emi.interestRate! > 0) {
                      final interest =
                          remainingPrincipal * (emi.interestRate! / 100);
                      totalLiability += interest;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.account_balance_rounded,
                              size: 18, color: theme.disabledColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(emi.loanName,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          AppFormatters.formatCurrency(
                              totalLiability, currency),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent, // Negative/Liability color
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),

          const Divider(height: 32),

          // Total Row
          totalLiabilitiesAsync.when(
            data: (total) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Liabilities',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor, fontWeight: FontWeight.w500)),
                Text(AppFormatters.formatCurrency(total, currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.redAccent,
                    )),
              ],
            ),
            loading: () => const SizedBox(),
            error: (e, s) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

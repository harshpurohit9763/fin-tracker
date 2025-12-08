// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:personal_finance/models/emi_model.dart';
// import 'package:personal_finance/controllers/emi_provider.dart';

// class FlippableEmiCard extends ConsumerWidget {
//   final Emi emi;
//   final String currency;
//   final String userName;
//   final VoidCallback onProfileTap;

//   const FlippableEmiCard({
//     super.key,
//     required this.emi,
//     required this.currency,
//     required this.userName,
//     required this.onProfileTap,
//   });

//   void _markAsPaid(BuildContext context, WidgetRef ref) {
//     final amountController =
//         TextEditingController(text: emi.monthlyEmiAmount.toString());
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//           child: AlertDialog(
//             backgroundColor: Colors.grey[900]?.withOpacity(0.8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(24),
//               side: BorderSide(color: Colors.white.withOpacity(0.2)),
//             ),
//             title: const Text(
//               'Confirm EMI Payment',
//               style:
//                   TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'Enter the amount paid for ${emi.loanName}.',
//                   style: const TextStyle(color: Colors.white70),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: amountController,
//                   keyboardType:
//                       const TextInputType.numberWithOptions(decimal: true),
//                   style: const TextStyle(color: Colors.white),
//                   decoration: InputDecoration(
//                     labelText: 'Amount Paid',
//                     labelStyle: const TextStyle(color: Colors.white70),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide:
//                           BorderSide(color: Colors.white.withOpacity(0.3)),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 child: const Text('Cancel',
//                     style: TextStyle(color: Colors.white70)),
//                 onPressed: () => Navigator.of(dialogContext).pop(),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF6B4BEE),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text('Confirm',
//                     style: TextStyle(color: Colors.white)),
//                 onPressed: () {
//                   final paidAmount = double.tryParse(amountController.text);
//                   if (paidAmount != null && paidAmount > 0) {
//                     ref
//                         .read(emiListProvider.notifier)
//                         .markEmiAsPaidWithAmount(emi, paidAmount);
//                     Navigator.of(dialogContext).pop();
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                           content: Text('Please enter a valid amount')),
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(40),
//       child: Card(
//         elevation: 10,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         child: Container(
//           width: double.infinity,
//           // height: 200,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(24),
//             gradient: const LinearGradient(
//               colors: [
//                 Color(0xFF6B4BEE),
//                 Color(0xFF4C3AEB),
//                 Color(0xFF8921AA),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Stack(
//             children: [
//               const _GlowEffect(),
//               BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(color: Colors.white.withOpacity(0.1)),
//                     color: Colors.white.withOpacity(0.05),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   spacing: 20,
//                   children: [
//                     _CardHeader(userName: userName, onProfileTap: onProfileTap),
//                     _CardMiddleSection(dueDate: emi.nextDueDate),
//                     _CardFooter(
//                       emi: emi,
//                       currency: currency,
//                       onPayNow: () => _markAsPaid(context, ref),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CardHeader extends StatelessWidget {
//   final String userName;
//   final VoidCallback onProfileTap;

//   const _CardHeader({required this.userName, required this.onProfileTap});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.white.withOpacity(0.2)),
//               ),
//               child: const Text(
//                 'Upcoming',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Next EMI Due',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.7),
//                 fontSize: 11,
//                 fontWeight: FontWeight.w500,
//                 letterSpacing: 1.1,
//               ),
//             ),
//             const Text(
//               'Credit Card EMI',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         GestureDetector(
//           onTap: onProfileTap,
//           child: CircleAvatar(
//             radius: 20,
//             backgroundColor: Colors.white.withOpacity(0.1),
//             child: Text(
//               userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _CardMiddleSection extends StatelessWidget {
//   final DateTime dueDate;

//   const _CardMiddleSection({required this.dueDate});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.white.withOpacity(0.2)),
//           ),
//           child:
//               const Icon(Icons.calendar_today, color: Colors.white, size: 18),
//         ),
//         const SizedBox(width: 10),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Due Date',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.7),
//                 fontSize: 11,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             Text(
//               DateFormat('MMM d, yyyy').format(dueDate),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _CardFooter extends StatelessWidget {
//   final Emi emi;
//   final String currency;
//   final VoidCallback onPayNow;

//   const _CardFooter(
//       {required this.emi, required this.currency, required this.onPayNow});

//   @override
//   Widget build(BuildContext context) {
//     final amountParts = emi.monthlyEmiAmount.toStringAsFixed(2).split('.');
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Total Amount',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.7),
//                 fontSize: 11,
//               ),
//             ),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.baseline,
//               textBaseline: TextBaseline.alphabetic,
//               children: [
//                 Text(
//                   amountParts[0],
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   '.${amountParts[1]}',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.8),
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   currency,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         ElevatedButton(
//           onPressed: onPayNow,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.white,
//             foregroundColor: const Color(0xFF4C3AEB),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//           ),
//           child: const Row(
//             children: [
//               Text(
//                 'Pay Now',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//               ),
//               SizedBox(width: 6),
//               Icon(Icons.arrow_forward, size: 16),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _GlowEffect extends StatelessWidget {
//   const _GlowEffect();

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Positioned(
//           top: -80,
//           right: -80,
//           child: Container(
//             width: 160,
//             height: 160,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.purple.withOpacity(0.5),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.purple.withOpacity(0.5),
//                   blurRadius: 80,
//                   spreadRadius: 40,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Positioned(
//           bottom: -80,
//           left: -80,
//           child: Container(
//             width: 160,
//             height: 160,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.blue.withOpacity(0.5),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.withOpacity(0.5),
//                   blurRadius: 80,
//                   spreadRadius: 40,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/models/emi_model.dart';
import 'package:personal_finance/controllers/emi_provider.dart';

class FlippableEmiCard extends ConsumerWidget {
  final Emi emi;
  final String currency;
  final String userName;
  final VoidCallback onProfileTap;

  const FlippableEmiCard({
    super.key,
    required this.emi,
    required this.currency,
    required this.userName,
    required this.onProfileTap,
  });

  // --- Logic for marking as paid (Preserved) ---
  void _markAsPaid(BuildContext context, WidgetRef ref) {
    final amountController =
        TextEditingController(text: emi.monthlyEmiAmount.toString());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E).withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            title: const Text(
              'Confirm Payment',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Paying for ${emi.loanName}',
                  style: TextStyle(color: theme.hintColor),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '$currency ',
                    filled: true,
                    fillColor: isDark ? Colors.black12 : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4BEE),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm'),
                onPressed: () {
                  final paidAmount = double.tryParse(amountController.text);
                  if (paidAmount != null && paidAmount > 0) {
                    ref
                        .read(emiListProvider.notifier)
                        .markEmiAsPaidWithAmount(emi, paidAmount);
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine gradient based on theme or hardcoded premium purple
    // You can swap these colors with Theme.of(context).colorScheme.primary if desired
    const List<Color> gradientColors = [
      Color(0xFF7F53AC), // Violet
      Color(0xFF647DEE), // Blue-Purple
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      height: 220, // Fixed height for consistent card look
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Background Glows
          const _GlowEffect(),

          // 2. Glass Overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // 3. Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Profile & "Upcoming"
                _CardHeader(userName: userName, onProfileTap: onProfileTap),

                // Middle Row: Loan Name & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emi.loanName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(emi.nextDueDate),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Icon decoration
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.credit_card, color: Colors.white),
                    )
                  ],
                ),

                // Bottom Row: Amount & Action
                _CardFooter(
                  amount: emi.monthlyEmiAmount,
                  currency: currency,
                  onPayNow: () => _markAsPaid(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;

  const _CardHeader({required this.userName, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Hello, $userName",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'UPCOMING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardFooter extends StatelessWidget {
  final double amount;
  final String currency;
  final VoidCallback onPayNow;

  const _CardFooter(
      {required this.amount, required this.currency, required this.onPayNow});

  @override
  Widget build(BuildContext context) {
    // Split amount for styling (e.g. 250.00 -> "250" and ".00")
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Due',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  parts[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '.${parts[1]} $currency',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Pay Button
        ElevatedButton(
          onPressed: onPayNow,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF647DEE), // Match gradient end
            elevation: 5,
            shadowColor: Colors.black26,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Row(
            children: [
              Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowEffect extends StatelessWidget {
  const _GlowEffect();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.2),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

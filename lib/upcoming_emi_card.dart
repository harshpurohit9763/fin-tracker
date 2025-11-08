import 'package:flutter/material.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/emi_model.dart';

class UpcomingEmiCard extends StatelessWidget {
  final Emi emi;
  final String currency;
  final String userName;
  final VoidCallback onProfileTap;

  const UpcomingEmiCard({
    super.key,
    required this.emi,
    required this.currency,
    required this.userName,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: AspectRatio(
          aspectRatio: 1.586, // Credit card aspect ratio
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next EMI Due',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                            Text(
                              emi.loanName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${AppFormatters.formatDate(emi.nextDueDate)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(userName,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            Text(
                                AppFormatters.formatCurrency(
                                    emi.monthlyEmiAmount, currency),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IconButton(
                        icon: const CircleAvatar(child: Icon(Icons.person)),
                        onPressed: onProfileTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';

class AuctionStatusChip extends StatelessWidget {
  const AuctionStatusChip({required this.status, super.key});

  final AuctionStatus status;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(status.label), visualDensity: VisualDensity.compact);
}

class AuctionOverviewCard extends StatelessWidget {
  const AuctionOverviewCard({required this.auction, super.key});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(
      hour: auction.startTimeMinutes ~/ 60,
      minute: auction.startTimeMinutes % 60,
    ).format(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel_rounded, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    auction.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                AuctionStatusChip(status: auction.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${DateFormat.yMMMd().format(auction.auctionDate)} · $time'
              '${auction.location.isEmpty ? '' : ' · ${auction.location}'}',
            ),
            const SizedBox(height: 4),
            Text(
              '${auction.auctionType.label} · '
              '${auction.cricketFormat == CricketFormat.custom ? auction.customFormat : auction.cricketFormat.label}',
            ),
            if (auction.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(auction.description),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.acid,
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: Padding(
      padding: EdgeInsets.all(size * .14),
      child: const CustomPaint(painter: _ReysMarkPainter()),
    ),
  );
}

class _ReysMarkPainter extends CustomPainter {
  const _ReysMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final route =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .13
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final path =
        Path()
          ..moveTo(size.width * .18, size.height * .77)
          ..cubicTo(
            size.width * .43,
            size.height * .77,
            size.width * .55,
            size.height * .61,
            size.width * .48,
            size.height * .47,
          )
          ..cubicTo(
            size.width * .41,
            size.height * .31,
            size.width * .55,
            size.height * .22,
            size.width * .78,
            size.height * .22,
          );
    canvas.drawPath(path, route);
    canvas.drawLine(
      Offset(size.width * .64, size.height * .1),
      Offset(size.width * .8, size.height * .22),
      route,
    );
    canvas.drawLine(
      Offset(size.width * .64, size.height * .34),
      Offset(size.width * .8, size.height * .22),
      route,
    );
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .77),
      size.width * .105,
      Paint()..color = AppColors.cyan,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.onIconTap,
  });
  final String eyebrow;
  final String title;
  final IconData icon;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 9,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
          ],
        ),
      ),
      InkWell(
        onTap: onIconTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, color: AppColors.ink, size: 21),
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.count,
    this.action,
    this.onTap,
  });
  final String title;
  final String? count;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Text(
            action!,
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TripStatus.moving => AppColors.green,
      TripStatus.matching || TripStatus.loading => AppColors.orange,
      TripStatus.documents => AppColors.blue,
      TripStatus.done => AppColors.muted,
      _ => AppColors.ink,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.onTap});
  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap ?? () => showTripDetails(context, trip),
    borderRadius: BorderRadius.circular(22),
    child: Ink(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                trip.number,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              StatusPill(status: trip.status),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.green,
                  size: 18,
                ),
              ),
              Expanded(
                child: Text(
                  trip.to,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.cargo} · ${weight(trip.weight)} т · ${trip.vehicle}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: trip.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE9EEEA),
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.near_me_outlined,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  trip.lastEvent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              Text(
                '+${money(trip.margin)}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class TinyTag extends StatelessWidget {
  const TinyTag({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

void showTripDetails(
  BuildContext context,
  Trip trip, {
  VoidCallback? onDocuments,
  VoidCallback? onDriver,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: .78,
          minChildSize: .5,
          maxChildSize: .94,
          expand: false,
          builder:
              (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        trip.number,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      StatusPill(status: trip.status),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    trip.route,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${trip.cargo} · ${weight(trip.weight)} т · ${trip.vehicle}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _DetailLine(label: 'Клиент', value: trip.client),
                        _DetailLine(
                          label: 'Перевозчик',
                          value:
                              trip.carrier.isEmpty
                                  ? 'Не назначен'
                                  : trip.carrier,
                        ),
                        _DetailLine(
                          label: 'Водитель',
                          value:
                              trip.driver.isEmpty ? 'Не назначен' : trip.driver,
                        ),
                        _DetailLine(
                          label: 'Машина',
                          value:
                              trip.truckPlate.isEmpty ? '—' : trip.truckPlate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MoneyBlock(
                          label: 'Клиент',
                          value: trip.clientRate,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MoneyBlock(
                          label: 'Перевозчик',
                          value: trip.carrierRate,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MoneyBlock(
                          label: 'Маржа',
                          value: trip.margin,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Контроль рейса',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _Timeline(
                    done: true,
                    title: 'Заявка зафиксирована',
                    detail: trip.client,
                  ),
                  _Timeline(
                    done: trip.carrier.isNotEmpty,
                    title: 'Перевозчик назначен',
                    detail:
                        trip.carrier.isEmpty
                            ? 'Ожидает действия'
                            : trip.carrier,
                  ),
                  _Timeline(
                    done: trip.progress > .2,
                    title: 'Водитель на маршруте',
                    detail: trip.lastEvent,
                  ),
                  _Timeline(
                    done: trip.documentsReady == trip.documentsTotal,
                    title: 'Документы собраны',
                    detail: '${trip.documentsReady} из ${trip.documentsTotal}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            if (onDocuments != null) {
                              onDocuments();
                            }
                          },
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Документы'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            if (onDriver != null) {
                              onDriver();
                            }
                          },
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('Водителю'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _MoneyBlock extends StatelessWidget {
  const _MoneyBlock({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
        ),
        const SizedBox(height: 4),
        Text(
          money(value),
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11.5,
          ),
        ),
      ],
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.done,
    required this.title,
    required this.detail,
  });
  final bool done;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? AppColors.green : AppColors.line,
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.more_horiz_rounded,
            color: done ? Colors.white : AppColors.muted,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

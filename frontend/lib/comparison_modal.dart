// comparison_modal.dart
//
// Full-screen comparison dialog: score cards, sectioned spec table,
// AI summary, and save comparison.
// Visual language: Robinhood-style neon deltas & premium dark chrome.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'apiservice.dart';
import 'auth_page.dart';
import 'comparison.dart';
import 'motorcycle.dart';

const Color _kPanelSurface = Color(0xFF121212);

/// Robinhood-style neon accent used for deltas (better / worse cues).
const Color _kNeonGreen = Color(0xFF00F593);
const Color _kNeonRed = Color(0xFFFF4F6D);

/// Dialog chrome tuned for stacked dark panels (#121212 + elevated panels).
const Color _kModalBg = Color(0xFF161616);

const Set<String> _inverseDeltaMetricKeys = {'weight', 'dry_weight'};
const Set<String> _neutralDeltaMetricKeys = {'displacement', 'engine_cc'};

String _powerTierLabel(double value) {
  if (value <= 25) return 'Low power';
  if (value <= 50) return 'Moderate';
  if (value <= 75) return 'High';
  return 'Extreme';
}

String _comfortTierLabel(double value) {
  if (value <= 25) return 'Harsh ride';
  if (value <= 50) return 'Moderate';
  if (value <= 75) return 'Comfortable';
  return 'Very comfortable';
}

String _bikeShortLabel(Motorcycle bike) {
  final t = '${bike.make} ${bike.model}';
  if (t.length <= 26) return t;
  return '${t.substring(0, 23)}...';
}

class ComparisonModal extends StatefulWidget {
  final Comparison comparison;
  final ApiService apiService;
  final ScaffoldMessengerState scaffoldMessenger;

  const ComparisonModal({
    super.key,
    required this.comparison,
    required this.apiService,
    required this.scaffoldMessenger,
  });

  static Future<void> show(
    BuildContext context, {
    required Comparison comparison,
    required ApiService apiService,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => ComparisonModal(
        comparison: comparison,
        apiService: apiService,
        scaffoldMessenger: messenger,
      ),
    );
  }

  @override
  State<ComparisonModal> createState() => _ComparisonModalState();
}

class _ComparisonModalState extends State<ComparisonModal> {
  bool _summaryLoading = false;
  String? _summaryText;
  bool _summaryUnavailable = false;
  String? _summaryErrorDetail;

  bool _comparisonSaved = false;

  Comparison get _c => widget.comparison;

  TextStyle _unavailableStyle(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurfaceVariant;
    return TextStyle(
      color: base.withValues(alpha: 0.52),
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );
  }

  TextStyle _valueStyle(BuildContext context, bool alignNumeric) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w500,
      fontFeatures: alignNumeric
          ? const [FontFeature.tabularFigures()]
          : const [FontFeature.proportionalFigures()],
    );
  }

  String _parseHttpErrorDetail(String body) {
    try {
      final data = jsonDecode(body);
      final d = data['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty) {
        return d.map((e) => e.toString()).join('; ');
      }
      return body.isNotEmpty ? body : '(empty body)';
    } catch (_) {
      return body.isNotEmpty ? body : '(unable to parse error body)';
    }
  }

  bool _effectiveDeltaIsBetter({
    required ComparisonResult result,
    required bool lowerIsBetter,
    String? specKey,
  }) {
    if (result == ComparisonResult.none || result == ComparisonResult.equal) {
      return false;
    }

    bool isBetter = result == ComparisonResult.higher;

    final key = specKey;
    if (key != null &&
        _inverseDeltaMetricKeys.contains(key) &&
        !lowerIsBetter) {
      isBetter = !isBetter;
    }
    return isBetter;
  }

  Map<String, dynamic> _summaryRequestBody() {
    return {
      'bike_a': _c.bike1.toComparisonPayload(),
      'bike_b': _c.bike2.toComparisonPayload(),
      'scores': {
        'power_score_a': _c.bike1.powerScore,
        'power_score_b': _c.bike2.powerScore,
        'comfort_score_a': _c.bike1.comfortScore,
        'comfort_score_b': _c.bike2.comfortScore,
        'beginner_a': _c.bike1.isBeginnerBike,
        'beginner_b': _c.bike2.isBeginnerBike,
        'ptw_a': _c.bike1.powerToWeightRatio,
        'ptw_b': _c.bike2.powerToWeightRatio,
      },
    };
  }

  Future<void> _fetchSummary() async {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthPage()),
      );
      return;
    }

    setState(() {
      _summaryLoading = true;
      _summaryUnavailable = false;
      _summaryText = null;
      _summaryErrorDetail = null;
    });

    try {
      final res = await widget.apiService.postJson(
        '/api/comparison/summary',
        _summaryRequestBody(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text = data['summary'];
        setState(() {
          _summaryLoading = false;
          _summaryErrorDetail = null;
          _summaryText = text is String ? text : null;
          if (_summaryText == null || _summaryText!.trim().isEmpty) {
            _summaryUnavailable = true;
          }
        });
      } else {
        final detail =
            '${res.statusCode}: ${_parseHttpErrorDetail(res.body)}';
        setState(() {
          _summaryLoading = false;
          _summaryUnavailable = true;
          _summaryErrorDetail = detail;
        });
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _summaryLoading = false;
        _summaryUnavailable = true;
        _summaryErrorDetail = '$e\n$st';
      });
    }
  }

  Future<void> _saveComparison() async {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthPage()),
      );
      return;
    }

    final bikeAId =
        '${_c.bike1.make}|${_c.bike1.model}|${_c.bike1.year}';
    final bikeBId =
        '${_c.bike2.make}|${_c.bike2.model}|${_c.bike2.year}';

    try {
      final res = await widget.apiService.postJson(
        '/api/favorites/comparison',
        {
          'bike_a_id': bikeAId,
          'bike_b_id': bikeBId,
          'summary': _summaryText,
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _comparisonSaved = true);
        widget.scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Comparison saved')),
        );
      }
    } catch (_) {
      /* silent — bookmark stays outline */
    }
  }

  Widget _primaryValueLine(
    BuildContext context, {
    required String raw,
    required bool alignNumeric,
  }) {
    final missing = isMissingModalDisplay(raw);

    final textAlign = alignNumeric ? TextAlign.right : TextAlign.left;

    final child = missing
        ? Text(
            'Data Unavailable',
            textAlign: textAlign,
            style: _unavailableStyle(context),
          )
        : Text(
            raw,
            textAlign: textAlign,
            style: _valueStyle(context, alignNumeric),
          );

    final alignment = alignNumeric
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Align(alignment: alignment, child: child);
  }

  String _deltaArrowChar({
    required bool isBetter,
    required bool lowerIsBetter,
  }) {
    return lowerIsBetter
        ? (isBetter ? '↓' : '↑')
        : (isBetter ? '↑' : '↓');
  }

  TextStyle _deltaStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: 0.02,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  Widget _neonDeltaBadge({
    required ComparisonResult result,
    required String differenceText,
    required bool lowerIsBetter,
    required CrossAxisAlignment align,
    required MainAxisAlignment rowAlign,
    String? specKey,
  }) {
    if (result == ComparisonResult.none) {
      return const SizedBox.shrink();
    }

    if (differenceText.isEmpty && result != ComparisonResult.equal) {
      return const SizedBox.shrink();
    }

    if (result == ComparisonResult.equal ||
        differenceText.toLowerCase() == 'equal') {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Align(
          alignment: align == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            'Equal',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final neutral =
        specKey != null && _neutralDeltaMetricKeys.contains(specKey);

    /// Delta direction / prefix (no subjective good/bad for neutral specs).
    final semanticsForBadge = neutral
        ? (result == ComparisonResult.higher)
        : _effectiveDeltaIsBetter(
            result: result,
            lowerIsBetter: lowerIsBetter,
            specKey: specKey,
          );

    final accent = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85);
    final color = neutral
        ? accent
        : (semanticsForBadge ? _kNeonGreen : _kNeonRed);
    final arrow = _deltaArrowChar(
      isBetter: semanticsForBadge,
      lowerIsBetter: lowerIsBetter,
    );
    final prefix = lowerIsBetter
        ? (semanticsForBadge ? '-' : '+')
        : (semanticsForBadge ? '+' : '-');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: rowAlign,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(arrow, style: _deltaStyle(color)),
          const SizedBox(width: 4),
          Text('$prefix$differenceText', style: _deltaStyle(color)),
        ],
      ),
    );
  }

  Widget _buildComparisonValue({
    required String value,
    required ComparisonResult result,
    required String differenceText,
    required bool lowerIsBetter,
    required bool alignNumeric,
    String? specKey,
  }) {
    final colAlign =
        alignNumeric ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final rowAlign =
        alignNumeric ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Column(
      crossAxisAlignment: colAlign,
      children: [
        _primaryValueLine(
          context,
          raw: value,
          alignNumeric: alignNumeric,
        ),
        _neonDeltaBadge(
          result: result,
          differenceText: differenceText,
          lowerIsBetter: lowerIsBetter,
          align: colAlign,
          rowAlign: rowAlign,
          specKey: specKey,
        ),
      ],
    );
  }

  Widget _scoreDeltaBelowBar({
    required ComparisonResult result,
    required String differenceText,
  }) {
    if (result == ComparisonResult.none || differenceText.isEmpty) {
      return const SizedBox(height: 18);
    }

    if (result == ComparisonResult.equal) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Equal',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isBetter = result == ComparisonResult.higher;
    final color = isBetter ? _kNeonGreen : _kNeonRed;
    final arrow =
        _deltaArrowChar(isBetter: isBetter, lowerIsBetter: false);
    final prefix = isBetter ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(arrow, style: _deltaStyle(color)),
          const SizedBox(width: 5),
          Text('$prefix$differenceText', style: _deltaStyle(color)),
        ],
      ),
    );
  }

  Widget _singleBikeScoreBlock({
    required ColorScheme colorScheme,
    required Motorcycle bike,
    required double? score,
    required String Function(double) tierFor,
    required ComparisonResult result,
    required String differenceText,
  }) {
    final unavailable = score == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _bikeShortLabel(bike),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: unavailable
                    ? Text(
                        'Data Unavailable',
                        textAlign: TextAlign.right,
                        style: _unavailableStyle(context),
                      )
                    : Text(
                        score.toStringAsFixed(1),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score != null ? (score / 100).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              color: colorScheme.primary,
            ),
          ),
          if (score != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                tierFor(score),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (!unavailable)
            _scoreDeltaBelowBar(
              result: result,
              differenceText: differenceText,
            ),
        ],
      ),
    );
  }

  Widget _scoreCardShell({
    required ColorScheme colorScheme,
    required String title,
    required List<Widget> children,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPanelSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _powerScorePair(ColorScheme colorScheme) {
    final powerMeta = _c.powerScoreComparisonMeta;
    final comfortMeta = _c.comfortScoreComparisonMeta;

    return Row(
      children: [
        _scoreCardShell(
          colorScheme: colorScheme,
          title: 'Power score',
          children: [
            _singleBikeScoreBlock(
              colorScheme: colorScheme,
              bike: _c.bike1,
              score: _c.bike1.powerScore,
              tierFor: _powerTierLabel,
              result: powerMeta.bike1Result,
              differenceText: powerMeta.differenceText,
            ),
            _singleBikeScoreBlock(
              colorScheme: colorScheme,
              bike: _c.bike2,
              score: _c.bike2.powerScore,
              tierFor: _powerTierLabel,
              result: powerMeta.bike2Result,
              differenceText: powerMeta.differenceText,
            ),
          ],
        ),
        const SizedBox(width: 14),
        _scoreCardShell(
          colorScheme: colorScheme,
          title: 'Comfort score',
          children: [
            _singleBikeScoreBlock(
              colorScheme: colorScheme,
              bike: _c.bike1,
              score: _c.bike1.comfortScore,
              tierFor: _comfortTierLabel,
              result: comfortMeta.bike1Result,
              differenceText: comfortMeta.differenceText,
            ),
            _singleBikeScoreBlock(
              colorScheme: colorScheme,
              bike: _c.bike2,
              score: _c.bike2.comfortScore,
              tierFor: _comfortTierLabel,
              result: comfortMeta.bike2Result,
              differenceText: comfortMeta.differenceText,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Dialog(
      insetPadding:
          EdgeInsets.symmetric(horizontal: mq.size.width >= 940 ? 32 : 12),
      backgroundColor: _kModalBg,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 880,
          maxHeight: mq.size.height * 0.9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Comparison',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Save comparison',
                    icon: Icon(
                      _comparisonSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: colorScheme.primary,
                    ),
                    onPressed: _saveComparison,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              child: Text(
                '${_c.bike1.make} ${_c.bike1.model} · ${_c.bike2.make} ${_c.bike2.model}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      _powerScorePair(colorScheme),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Spec',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${_c.bike1.make} ${_c.bike1.model}',
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${_c.bike2.make} ${_c.bike2.model}',
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      for (final section in _c.comparisonSections) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 8),
                          child: Text(
                            section.title,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.35,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        for (final row in section.rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    row.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _buildComparisonValue(
                                    value: row.bike1,
                                    result: row.bike1Result,
                                    differenceText: row.differenceText,
                                    lowerIsBetter: row.lowerIsBetter,
                                    alignNumeric: row.rightAlignValues,
                                    specKey: row.specKey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: _buildComparisonValue(
                                    value: row.bike2,
                                    result: row.bike2Result,
                                    differenceText: row.differenceText,
                                    lowerIsBetter: row.lowerIsBetter,
                                    alignNumeric: row.rightAlignValues,
                                    specKey: row.specKey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _summaryLoading ? null : _fetchSummary,
                          child: _summaryLoading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Loading…',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome_outlined),
                                    SizedBox(width: 8),
                                    Text(
                                      'Get AI Summary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_summaryErrorDetail != null && !_summaryLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: SelectableText(
                            _summaryErrorDetail!,
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        )
                      else if (_summaryUnavailable && !_summaryLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            'Summary unavailable',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (_summaryText != null && _summaryText!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _kPanelSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              _summaryText!,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ShaonSignalApp());

class Candle {
  final double open, high, low, close;
  const Candle(this.open, this.high, this.low, this.close);
}

class Analysis {
  final String signal;
  final int confidence;
  final double price, rsi;
  final int bull, bear;
  final List<String> reasons;
  const Analysis(this.signal, this.confidence, this.price, this.rsi,
      this.bull, this.bear, this.reasons);
}

List<double> ema(List<double> values, int period) {
  final alpha = 2 / (period + 1);
  final out = <double>[];
  for (var i = 0; i < values.length; i++) {
    out.add(i == 0 ? values[i] : alpha * values[i] + (1 - alpha) * out[i - 1]);
  }
  return out;
}

double rsi(List<double> close, [int period = 14]) {
  if (close.length <= period) return 50;
  var gain = 0.0, loss = 0.0;
  for (var i = 1; i <= period; i++) {
    final d = close[i] - close[i - 1];
    if (d > 0) gain += d; else loss -= d;
  }
  var avgGain = gain / period, avgLoss = loss / period;
  for (var i = period + 1; i < close.length; i++) {
    final d = close[i] - close[i - 1];
    avgGain = (avgGain * (period - 1) + max(d, 0)) / period;
    avgLoss = (avgLoss * (period - 1) + max(-d, 0)) / period;
  }
  if (avgLoss == 0) return 100;
  final rs = avgGain / avgLoss;
  return 100 - 100 / (1 + rs);
}

Analysis analyze(List<Candle> candles) {
  if (candles.length < 25) {
    return const Analysis('NO SIGNAL', 0, 0, 50, 0, 0, ['At least 25 candles are required.']);
  }
  final closes = candles.map((c) => c.close).toList();
  final fast = ema(closes, 9).last;
  final slow = ema(closes, 21).last;
  final rv = rsi(closes);
  final recent = closes.sublist(closes.length - 20);
  final mid = recent.reduce((a, b) => a + b) / 20;
  final variance = recent.map((v) => pow(v - mid, 2)).reduce((a, b) => a + b) / 19;
  final sd = sqrt(variance);
  final upper = mid + 2 * sd, lower = mid - 2 * sd;
  final last = candles.last;
  final bullChecks = <(bool, String)>[
    (fast > slow, 'EMA 9 is above EMA 21'),
    (rv < 35, 'RSI is below 35'),
    (last.close <= lower * 1.001, 'Price is near the lower Bollinger Band'),
    (last.close > last.open, 'Latest candle closed bullish'),
  ];
  final bearChecks = <(bool, String)>[
    (fast < slow, 'EMA 9 is below EMA 21'),
    (rv > 65, 'RSI is above 65'),
    (last.close >= upper * .999, 'Price is near the upper Bollinger Band'),
    (last.close < last.open, 'Latest candle closed bearish'),
  ];
  final bull = bullChecks.where((x) => x.$1).length;
  final bear = bearChecks.where((x) => x.$1).length;
  if (bull >= 3 && bull > bear) {
    return Analysis('CALL (UP)', bull * 25, last.close, rv, bull, bear,
        bullChecks.where((x) => x.$1).map((x) => x.$2).toList());
  }
  if (bear >= 3 && bear > bull) {
    return Analysis('PUT (DOWN)', bear * 25, last.close, rv, bull, bear,
        bearChecks.where((x) => x.$1).map((x) => x.$2).toList());
  }
  return Analysis('NO SIGNAL', max(bull, bear) * 25, last.close, rv, bull, bear,
      ['Bullish score: $bull/4 • Bearish score: $bear/4', 'Fewer than 3 conditions aligned.']);
}

List<Candle> sampleCandles() {
  final random = Random(42);
  var close = 1.085;
  final rows = <Candle>[];
  for (var i = 0; i < 80; i++) {
    final open = close;
    close *= 1 + (random.nextDouble() - .5) * .0024;
    final high = max(open, close) + random.nextDouble() * .0005;
    final low = min(open, close) - random.nextDouble() * .0005;
    rows.add(Candle(open, high, low, close));
  }
  return rows;
}

class ShaonSignalApp extends StatelessWidget {
  const ShaonSignalApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SHAON SIGNAL',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF08111F),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF36D399), secondary: Color(0xFF60A5FA),
        surface: Color(0xFF111D2D),
      ),
    ),
    home: const Dashboard(),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String asset = 'EUR/USD';
  String timeframe = '1m';
  late Analysis result;
  @override
  void initState() {
    super.initState();
    result = analyze(sampleCandles());
  }
  void refreshDemo() => setState(() => result = analyze(sampleCandles()));
  @override
  Widget build(BuildContext context) {
    final bullish = result.signal.startsWith('CALL');
    final bearish = result.signal.startsWith('PUT');
    final signalColor = bullish ? const Color(0xFF36D399) :
        bearish ? const Color(0xFFF87171) : const Color(0xFFFBBF24);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF08111F),
        title: const Row(children: [
          Icon(Icons.show_chart, color: Color(0xFF36D399)),
          SizedBox(width: 9),
          Text('SHAON SIGNAL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        actions: [IconButton(onPressed: refreshDemo, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF14283B), Color(0xFF101A2A)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF26384C)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MARKET ANALYSIS • DEMO', style: TextStyle(color: Color(0xFF9FB0C4), fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: asset, dropdownColor: const Color(0xFF142235),
                decoration: const InputDecoration(labelText: 'Asset', border: OutlineInputBorder()),
                items: ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => asset = v!),
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                value: timeframe, dropdownColor: const Color(0xFF142235),
                decoration: const InputDecoration(labelText: 'Timeframe', border: OutlineInputBorder()),
                items: ['1m', '5m', '15m']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => timeframe = v!),
              )),
            ]),
            const SizedBox(height: 20),
            Text(asset, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(color: signalColor.withOpacity(.10), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(result.signal, style: TextStyle(color: signalColor, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Demo score: ${result.confidence}%', style: TextStyle(color: signalColor)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: metric('LAST CLOSE', result.price.toStringAsFixed(5))),
          const SizedBox(width: 12),
          Expanded(child: metric('RSI (14)', result.rsi.toStringAsFixed(1))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: metric('BULLISH', '${result.bull}/4')),
          const SizedBox(width: 12),
          Expanded(child: metric('BEARISH', '${result.bear}/4')),
        ]),
        const SizedBox(height: 20),
        const Text('SIGNAL REASONS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...result.reasons.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: const Color(0xFF111D2D), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [const Icon(Icons.check_circle_outline, color: Color(0xFF60A5FA), size: 18), const SizedBox(width: 10), Expanded(child: Text(r))]),
        )),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: refreshDemo, icon: const Icon(Icons.refresh), label: const Text('Refresh Demo Analysis')),
        const SizedBox(height: 18),
        const Text(
          'IMPORTANT: This build uses generated sample candles, not live market prices. '
          'The score is not a probability of profit or a guarantee. For learning only; '
          'do not use it to make real-money trading decisions.',
          style: TextStyle(color: Color(0xFF9FB0C4), fontSize: 12, height: 1.5),
        ),
      ]),
    );
  }

  Widget metric(String label, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF111D2D), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF9FB0C4), fontSize: 10, letterSpacing: 1)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ]),
  );
}

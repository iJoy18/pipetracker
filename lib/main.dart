import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(PipeTrackerApp());

class PipeTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipe Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: SystemSelectorScreen(),
    );
  }
}

enum PipeLineType { liquid, suction, discharge }

extension PipeLineTypeExtension on PipeLineType {
  String get label {
    switch (this) {
      case PipeLineType.liquid:
        return 'Liquid';
      case PipeLineType.suction:
        return 'Suction';
      case PipeLineType.discharge:
        return 'Discharge';
    }
  }
}

class PipeSizeSystem {
  final String name;
  Map<PipeLineType, double> lines;

  PipeSizeSystem({required this.name, required this.lines});

  double get total => lines.values.reduce((a, b) => a + b);
  int get materialLengthCount => (total / 6).ceil();

  String getInsulationThickness(PipeLineType type, bool isThreeLine) {
    if (isThreeLine) {
      switch (type) {
        case PipeLineType.liquid:
          return ["1/4\"", "3/8\"", "1/2\"", "5/8\""].contains(name) ? "19mm" : "25mm";
        case PipeLineType.suction:
          return ["1/4\"", "3/8\"", "1/2\"", "5/8\""].contains(name) ? "19mm" : "25mm";
        case PipeLineType.discharge:
          return "32mm";
      }
    } else {
      switch (type) {
        case PipeLineType.liquid:
          return ["1/4\"", "3/8\"", "1/2\"", "5/8\""].contains(name) ? "19mm" : "25mm";
        case PipeLineType.suction:
          return "32mm";
        default:
          return "-";
      }
    }
  }

  int getInsulationCount(PipeLineType type) => (lines[type]! / 2).ceil();
}

class SystemSelectorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Pipe System Type')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('2-Line Pipe System'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PipeTrackerScreen(isThreeLine: false),
                ),
              ),
            ),
            ElevatedButton(
              child: Text('3-Line Pipe System'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PipeTrackerScreen(isThreeLine: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PipeTrackerScreen extends StatefulWidget {
  final bool isThreeLine;

  PipeTrackerScreen({required this.isThreeLine});

  @override
  _PipeTrackerScreenState createState() => _PipeTrackerScreenState();
}

class _PipeTrackerScreenState extends State<PipeTrackerScreen> {
  late List<PipeLineType> lineTypes;
  late List<PipeSizeSystem> pipeSystems;

  String selectedSize = "1/4\"";
  late PipeLineType selectedType;
  final TextEditingController lengthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    lineTypes = widget.isThreeLine
        ? [PipeLineType.liquid, PipeLineType.suction, PipeLineType.discharge]
        : [PipeLineType.liquid, PipeLineType.suction];

    pipeSystems = [
      "1/4\"", "3/8\"", "1/2\"", "5/8\"", "3/4\"",
      "7/8\"", "1\"", "1' 1/8\"", "1' 3/8\""
    ].map((size) => PipeSizeSystem(
      name: size,
      lines: {for (var type in lineTypes) type: 0.0},
    )).toList();

    selectedType = lineTypes.first;
  }

  double get grandTotal => pipeSystems.fold(0.0, (sum, ps) => sum + ps.total);
  int get grandMaterialCount => pipeSystems.fold(0, (sum, ps) => sum + ps.materialLengthCount);

  void addLength() {
    final entered = double.tryParse(lengthController.text);
    if (entered == null || entered < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid length.")),
      );
      return;
    }

    final system = pipeSystems.firstWhere((ps) => ps.name == selectedSize);
    system.lines[selectedType] = (system.lines[selectedType] ?? 0.0) + entered;

    setState(() {
      lengthController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isThreeLine ? "Pipe Tracker (3-Line)" : "Pipe Tracker (2-Line)")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text("Add Pipe Length", style: Theme.of(context).textTheme.titleLarge),

            DropdownButton<String>(
              value: selectedSize,
              isExpanded: true,
              items: pipeSystems.map((ps) {
                return DropdownMenuItem<String>(
                  value: ps.name,
                  child: Text(ps.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedSize = value!),
            ),

            DropdownButton<PipeLineType>(
              value: selectedType,
              isExpanded: true,
              items: lineTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedType = value!),
            ),

            TextField(
              controller: lengthController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: "Length (m)"),
            ),

            ElevatedButton(
              onPressed: addLength,
              child: Text("Add Length"),
            ),

            Divider(height: 32),

            Text("Current Pipe Length Totals", style: Theme.of(context).textTheme.titleLarge),
            ...pipeSystems.map((system) {
              return ExpansionTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pipe Size: ${system.name}"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total: ${system.total.toStringAsFixed(2)} m"),
                        Text("Materials: ${system.materialLengthCount} x 6m", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                children: [
                  ...lineTypes.map((type) {
                    final len = system.lines[type]!;
                    return ListTile(
                      title: Text("  ${type.label} (Insulation: ${system.getInsulationThickness(type, widget.isThreeLine)})"),
                      subtitle: Text("  Insulation Material: ${system.getInsulationCount(type)} x 2m"),
                      trailing: Text("${len.toStringAsFixed(2)} m"),
                    );
                  }),
                ],
              );
            }),

            ListTile(
              title: Text("GRAND TOTAL (all pipes)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Materials: $grandMaterialCount x 6m"),
              trailing: Text("${grandTotal.toStringAsFixed(2)} m", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

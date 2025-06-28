import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupDetailScreen extends StatefulWidget {
  final DocumentSnapshot group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late DocumentReference groupRef;
  late Stream<QuerySnapshot> expensesStream;
  int totalAmount = 0;

  @override
  void initState() {
    super.initState();
    groupRef = widget.group.reference;
    expensesStream = getExpenses();
    fetchTotalAmount();
  }

  Stream<QuerySnapshot> getExpenses() {
    return groupRef.collection('expenses').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> fetchTotalAmount() async {
    int updatedTotal = 0;
    final snapshot = await groupRef.collection('expenses').get();
    for (var doc in snapshot.docs) {
      updatedTotal += (doc['amount'] as num).toInt();
    }
    await groupRef.update({'total': updatedTotal});
    setState(() => totalAmount = updatedTotal);
  }

  Future<Map<String, String>> getUserMap(List<String> uids) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids)
        .get();

    final Map<String, String> uidToName = {};
    for (var doc in snapshot.docs) {
      uidToName[doc.id] = doc['name'] ?? doc['email'] ?? 'Unknown';
    }
    return uidToName;
  }

  Future<Map<String, Map<String, double>>> calculateTable(List<String> members) async {
    final expensesSnapshot = await getExpenses().first;
    final expenses = expensesSnapshot.docs;

    Map<String, double> paid = {};
    Map<String, double> owes = {};

    for (var member in members) {
      paid[member] = 0.0;
      owes[member] = 0.0;
    }

    for (var doc in expenses) {
      final data = doc.data() as Map<String, dynamic>;
      final addedBy = data['addedBy'];
      final amount = (data['amount'] as num).toDouble();
      final split = Map<String, dynamic>.from(data['split'] ?? {});

      paid[addedBy] = (paid[addedBy] ?? 0) + amount;

      for (var entry in split.entries) {
        final member = entry.key;
        final share = (entry.value as num).toDouble();
        owes[member] = (owes[member] ?? 0) + share;
      }
    }

    final Map<String, Map<String, double>> result = {};
    for (var member in members) {
      result[member] = {
        'paid': paid[member] ?? 0,
        'owed': owes[member] ?? 0,
        'net': (paid[member] ?? 0) - (owes[member] ?? 0),
      };
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> generateSettlements(List<String> members) async {
    final balances = await calculateTable(members);
    List<Map<String, dynamic>> settlements = [];

    List<MapEntry<String, double>> creditors = [];
    List<MapEntry<String, double>> debtors = [];

    balances.forEach((uid, data) {
      final net = data['net']!;
      if (net > 0) creditors.add(MapEntry(uid, net));
      if (net < 0) debtors.add(MapEntry(uid, net.abs()));
    });

    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];

      final amount = debtor.value < creditor.value ? debtor.value : creditor.value;

      settlements.add({
        'from': debtor.key,
        'to': creditor.key,
        'amount': amount,
      });

      debtors[i] = MapEntry(debtor.key, debtor.value - amount);
      creditors[j] = MapEntry(creditor.key, creditor.value - amount);

      if (debtors[i].value == 0) i++;
      if (creditors[j].value == 0) j++;
    }

    return settlements;
  }

  Future<void> _deleteExpense(DocumentReference ref) async {
    await ref.delete();
    fetchTotalAmount();
  }

  void _addExpense(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Expense"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Expense Title"),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? "Enter valid amount" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              final title = titleController.text.trim();
              final amount = double.parse(amountController.text.trim());
              final user = FirebaseAuth.instance.currentUser;
              final members = List<String>.from(widget.group['members'] ?? []);
              final sharePerPerson = amount / members.length;

              final Map<String, double> split = {
                for (var member in members) member: sharePerPerson,
              };

              await groupRef.collection('expenses').add({
                'title': title,
                'amount': amount,
                'addedBy': user?.uid ?? 'unknown',
                'split': split,
                'createdAt': FieldValue.serverTimestamp(),
              });

              fetchTotalAmount();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _copyGroupId() {
    final groupId = widget.group.id;
    Clipboard.setData(ClipboardData(text: groupId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Group ID copied: $groupId")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupName = widget.group['name'];
    final members = List<String>.from(widget.group['members'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Group ID',
            onPressed: _copyGroupId,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, String>>(
        future: getUserMap(members),
        builder: (context, userMapSnap) {
          if (!userMapSnap.hasData) return const Center(child: CircularProgressIndicator());
          final uidToName = userMapSnap.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text("Total Spent"),
                subtitle: Text("₹$totalAmount", style: const TextStyle(fontSize: 20)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Members:", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Text(members.map((uid) => uidToName[uid] ?? uid).join(', ')),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Expenses", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: expensesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final expenses = snapshot.data!.docs;

                    if (expenses.isEmpty) {
                      return const Center(child: Text("No expenses yet."));
                    }

                    return ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final doc = expenses[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final Map<String, dynamic> split = Map<String, dynamic>.from(data['split'] ?? {});
                        final addedBy = uidToName[data['addedBy']] ?? data['addedBy'];

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          child: ListTile(
                            title: Text("${data['title']} - ₹${data['amount']}"),
                            subtitle: Text("Added by: $addedBy\n" + split.entries.map((e) => "${uidToName[e.key] ?? e.key}: ₹${(e.value as num).toStringAsFixed(2)}").join("\n")),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExpense(doc.reference),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Net Balances", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              FutureBuilder<Map<String, Map<String, double>>>(
                future: calculateTable(members),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Calculating..."),
                  );

                  final data = snapshot.data!;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Paid")),
                        DataColumn(label: Text("Owes")),
                        DataColumn(label: Text("Net")),
                      ],
                      rows: data.entries.map((entry) {
                        final uid = entry.key;
                        final name = uidToName[uid] ?? uid;
                        final values = entry.value;
                        return DataRow(cells: [
                          DataCell(Text(name)),
                          DataCell(Text("₹${values['paid']!.toStringAsFixed(2)}")),
                          DataCell(Text("₹${values['owed']!.toStringAsFixed(2)}")),
                          DataCell(Text("₹${values['net']!.toStringAsFixed(2)}")),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text("Settle Up", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: generateSettlements(members),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Calculating settlements..."),
                  );

                  final settlements = snapshot.data!;
                  if (settlements.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("All balances are settled!"),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("From")),
                        DataColumn(label: Text("To")),
                        DataColumn(label: Text("Amount")),
                      ],
                      rows: settlements.map((s) {
                        final fromName = uidToName[s['from']] ?? s['from'];
                        final toName = uidToName[s['to']] ?? s['to'];
                        final amt = (s['amount'] as double).toStringAsFixed(2);
                        return DataRow(cells: [
                          DataCell(Text(fromName)),
                          DataCell(Text(toName)),
                          DataCell(Text("₹$amt")),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
    );
  }
}

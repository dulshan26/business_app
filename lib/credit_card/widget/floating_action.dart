import 'package:flutter/material.dart';
import 'package:own/firebase/firestore.dart';

class Floating extends StatefulWidget {
  const Floating({super.key});

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> {
  String selectedCard = "HNB";
  String transactionType = "Monthly bill";
  String cardHolder = "";

  final dateController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final holderController = TextEditingController();

  final FirestoreService service = FirestoreService();

  @override
  void initState() {
    super.initState();
    dateController.text = DateTime.now().toString();
  }

  @override
  void dispose() {
    dateController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    holderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) => AlertDialog(
                title: const Text("Add Transaction"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "select Date",
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2027),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              dateController.text = pickedDate.toString().split(
                                " ",
                              )[0];
                            });
                          }
                        },
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                        ),
                      ),
                      DropdownButton<String>(
                        value: selectedCard,
                        items: <String>['HNB', 'DFCC', 'Pan Asia']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            selectedCard = newValue!;
                          });
                        },
                      ),
                      DropdownButton<String>(
                        value: transactionType,
                        items: <String>['Cash Credit', 'Monthly bill']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            transactionType = newValue!;
                          });
                        },
                      ),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: "Amount"),
                        keyboardType: TextInputType.number,
                      ),
                      DropdownButton<String>(
                        value: cardHolder.isEmpty ? null : cardHolder,
                        items: <String>['Dulshan', 'Kavindi']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            cardHolder = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      service.addTransaction(
                        card: selectedCard,
                        date: dateController.text,
                        decription: descriptionController.text,
                        amount: double.parse(priceController.text),
                        type: transactionType,
                        holder: cardHolder,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction added!')),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Icon(Icons.payment),
    );
  }
}

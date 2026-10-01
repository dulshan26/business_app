import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/customer/customer_model.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = Get.put(CustomerController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Directory'),
                Text(
                  'Total: ${controller.totalCustomerCount} customers',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            );
          }),
          bottom: TabBar(
            tabs: [
              Obx(
                () => Tab(
                  text: 'All (${controller.normalCustomerList.length})',
                  icon: Icon(Icons.people_outline_rounded),
                ),
              ),
              Obx(
                () => Tab(
                  text: 'Returned (${controller.returnedCustomerList.length})',
                  icon: Icon(Icons.assignment_returned_rounded),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search field container
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
                decoration: InputDecoration(
                  labelText: 'Search Customer...',
                  hintText: 'Enter name or phone number',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Obx(
                    () => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => controller.searchQuery.value = '',
                          )
                        : const SizedBox.shrink(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // OPTION 2: Display a descriptive banner chip (Great for showing search results count)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    // If searching, show "Showing X of Y" otherwise show "All Customers (Y)"
                    if (controller.searchQuery.value.isNotEmpty) {
                      return Text(
                        'Found ${controller.filterCustomerCount} matches',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      );
                    }
                    return Text(
                      'All Customers (${controller.totalCustomerCount})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Main List area
            Expanded(
              child: TabBarView(
                children: [
                  Obx(() {
                    return _buildCustomerListModel(
                      controller,
                      controller.normalCustomerList,
                      isReturnedList: false,
                    );
                  }),
                  Obx(() {
                    return _buildCustomerListModel(
                      controller,
                      controller.returnedCustomerList,
                      isReturnedList: true,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCustomerListModel(
  CustomerController controller,
  List<CustomerModel> customerList, {
  required bool isReturnedList,
}) {
  if (customerList.isEmpty) {
    return Center(
      child: Text(
        isReturnedList
            ? 'No returned customers found.'
            : 'No customers found matching that criteria.',
      ),
    );
  }

  return ListView.builder(
    itemCount: customerList.length,
    itemBuilder: (context, index) {
      final customer = customerList[index];

      return Align(
        alignment: Alignment.topCenter,

        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(customer.name),
              subtitle: Text(customer.phone ?? 'No phone'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_outlined),
                color: Colors.redAccent,
                onPressed: () {
                  Get.defaultDialog(
                    title: "Delete",
                    middleText: 'Are you sure you want to delete?',
                    textConfirm: 'Delete',
                    textCancel: 'Cancel',
                    onConfirm: () async {
                      Get.back();
                      await controller.deleteCustomer(customer.id);
                    },
                  );
                },
              ),
              onTap: () async {
                if (customer.phone != null) {
                  controller.checkAndNavigate(customer.phone!);
                }
              },
            ),
          ),
        ),
      );
    },
  );
}

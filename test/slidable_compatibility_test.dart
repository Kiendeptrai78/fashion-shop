import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Slidable reveals and invokes its end action', (tester) async {
    var actionInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => actionInvoked = true,
                  label: 'Delete',
                ),
              ],
            ),
            child: const ListTile(title: Text('Product')),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Product'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(actionInvoked, isTrue);
    expect(tester.takeException(), isNull);
  });
}

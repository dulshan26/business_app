import 'package:flutter_test/flutter_test.dart';
import 'package:own/ecommerce/models/cart_model.dart';
import 'package:own/ecommerce/models/product_model.dart';
import 'package:own/getxpac/sales_item/item_model.dart';

void main() {
  group('ProductModel', () {
    test('parses stock field aliases and creates a legacy default variant', () {
      final product = ProductModel.fromMap({
        'item_name': 'Door Sensor',
        'price': '2500.50',
        'balance': '20',
        'images': ['sensor.jpg'],
      }, id: 'sensor-id');

      expect(product.id, 'sensor-id');
      expect(product.name, 'Door Sensor');
      expect(product.price, 2500.5);
      expect(product.stock, 20);
      expect(product.hasVariants, isFalse);
      expect(product.variants, hasLength(1));
      expect(product.variants.single.id, 'default');
      expect(product.startingPrice, 2500.5);
      expect(product.totalVariantStock, 20);
    });

    test('calculates price and stock from active variants', () {
      final product = ProductModel.fromMap({
        'name': 'Switch',
        'price': 900,
        'stock': 99,
        'options': [
          {
            'name': 'Gang',
            'values': ['1', '2'],
          },
        ],
        'variants': [
          {
            'id': 'one',
            'attributes': {'Gang': '1'},
            'sku': 'SW-1',
            'price': 750,
            'stock': 4,
            'isActive': true,
          },
          {
            'id': 'two',
            'attributes': {'Gang': '2'},
            'sku': 'SW-2',
            'price': 1200,
            'stock': 6,
            'isActive': false,
          },
        ],
      });

      expect(product.hasVariants, isTrue);
      expect(product.options.single.values, ['1', '2']);
      expect(product.startingPrice, 750);
      expect(product.totalVariantStock, 4);
      expect(product.activeVariants.map((variant) => variant.id), ['one']);
      expect(product.toMap()['variants'], hasLength(2));
    });

    test('converts nested option prices into selectable cart variants', () {
      final product = ProductModel.fromMap({
        'name': 'Shirt',
        'price': 100,
        'balance': 7,
        'options': [
          {
            'name': 'Size',
            'variants': [
              {'name': 'Small', 'price': 100, 'stock': 5},
              {'name': 'Large', 'price': 150, 'stock': 2},
            ],
          },
          {
            'name': 'Color',
            'variants': [
              {'name': 'Black', 'price': 20, 'stock': 4},
              {'name': 'White', 'price': 30, 'stock': 1},
            ],
          },
        ],
      });

      final smallBlack = product.variants.singleWhere(
        (variant) =>
            variant.attributes['Size'] == 'Small' &&
            variant.attributes['Color'] == 'Black',
      );
      final largeWhite = product.variants.singleWhere(
        (variant) =>
            variant.attributes['Size'] == 'Large' &&
            variant.attributes['Color'] == 'White',
      );

      expect(product.options.map((option) => option.values), [
        ['Small', 'Large'],
        ['Black', 'White'],
      ]);
      expect(smallBlack.price, 120);
      expect(smallBlack.stock, 4);
      expect(largeWhite.price, 180);
      expect(largeWhite.stock, 1);
      expect(product.totalVariantStock, 7);
      expect(product.toMap()['options'], [
        {
          'name': 'Size',
          'variants': [
            {'name': 'Small', 'price': 100.0, 'stock': 5},
            {'name': 'Large', 'price': 150.0, 'stock': 2},
          ],
        },
        {
          'name': 'Color',
          'variants': [
            {'name': 'Black', 'price': 20.0, 'stock': 4},
            {'name': 'White', 'price': 30.0, 'stock': 1},
          ],
        },
      ]);
      expect(product.toMap().containsKey('variants'), isFalse);
    });
  });

  test('ItemModel treats default-only products as non-selectable', () {
    final item = ItemModel.fromMap({
      'item_name': 'Door Sensor',
      'price': 2500,
      'balance': 20,
    }, id: 'sensor-id');

    expect(item.hasVariants, isFalse);
    expect(item.variants, isEmpty);
    expect(item.totalVariantStock, 20);
  });

  test(
    'ItemModel saves option variants with their stock nested under options',
    () {
      final item = ItemModel.fromMap({
        'item_name': 'T-shirt',
        'price': 2500,
        'balance': 7,
        'options': [
          {
            'name': 'Size',
            'variants': [
              {'name': 'Small', 'price': 2800, 'stock': 3},
              {'name': 'Medium', 'price': 3100, 'stock': 4},
            ],
          },
        ],
      });

      expect(item.options.single.variants.map((variant) => variant.name), [
        'Small',
        'Medium',
      ]);
      expect(item.options.single.variants.map((variant) => variant.price), [
        2800,
        3100,
      ]);
      expect(item.totalVariantStock, 7);
      expect(item.toMap()['options'], [
        {
          'name': 'Size',
          'variants': [
            {'name': 'Small', 'price': 2800.0, 'stock': 3},
            {'name': 'Medium', 'price': 3100.0, 'stock': 4},
          ],
        },
      ]);
      expect(item.toMap().containsKey('variants'), isFalse);
    },
  );

  test('ItemModel reads legacy option values and converts matching stock', () {
    final item = ItemModel.fromMap({
      'item_name': 'T-shirt',
      'price': 2500,
      'balance': 7,
      'options': [
        {
          'name': 'Size',
          'values': ['Small', 'Medium'],
        },
      ],
      'variants': [
        {
          'attributes': {'Size': 'Small'},
          'price': 2600,
          'stock': 3,
          'isActive': true,
        },
        {
          'attributes': {'Size': 'Medium'},
          'price': 2700,
          'stock': 4,
          'isActive': true,
        },
      ],
    });

    expect(item.options.single.variants.map((variant) => variant.stock), [
      3,
      4,
    ]);
    expect(item.options.single.variants.map((variant) => variant.price), [
      2600,
      2700,
    ]);
    expect(item.toMap().containsKey('variants'), isFalse);
  });

  test('CartItem preserves selected variant details through serialization', () {
    final item = CartItem(
      itemId: 'switch-id',
      variantId: 'black-1-gang',
      productName: 'Smart Switch',
      productImage: 'switch.jpg',
      selectedAttributes: const {'Gang': '1 Gang', 'Color': 'Black'},
      sku: 'SW-1-B',
      unitPrice: 2700,
      quantity: 2,
    );

    final restored = CartItem.fromMap(item.toMap());

    expect(restored.itemId, 'switch-id');
    expect(restored.variantId, 'black-1-gang');
    expect(restored.selectedAttributes, item.selectedAttributes);
    expect(restored.sku, 'SW-1-B');
    expect(restored.unitPrice, 2700);
    expect(restored.subtotal, 5400);
  });
}

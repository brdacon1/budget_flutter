import 'package:cloud_firestore/cloud_firestore.dart';

class ProductPriceRemoteDataSource {
  final FirebaseFirestore _firestore;
  ProductPriceRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _collection(String userUid) =>
      _firestore.collection('EMPRESAS/$userUid/USERS/$userUid/PRICELIST');

  Future<List<Map<String, dynamic>>> getProducts(String userUid) async {
    final snapshot = await _collection(userUid).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<DocumentReference> addProduct(String userUid, Map<String, dynamic> data) async {
    return await _collection(userUid).add(data);
  }

  Future<void> updateProduct(String userUid, String id, Map<String, dynamic> data) async {
    await _collection(userUid).doc(id).update(data);
  }

  Future<void> deleteProduct(String userUid, String id) async {
    await _collection(userUid).doc(id).delete();
  }
}

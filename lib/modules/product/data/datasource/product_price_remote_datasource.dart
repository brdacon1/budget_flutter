import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;

class ProductPriceRemoteDataSource {
  final FirebaseFirestore _firestore;
  ProductPriceRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection('EMPRESAS/${UID.user}/USERS/${UID.user}/PRICELIST');

  Future<List<Map<String, dynamic>>> getProducts() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<DocumentReference> addProduct(Map<String, dynamic> data) async {
    return await _collection.add(data);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _collection.doc(id).delete();
  }
}

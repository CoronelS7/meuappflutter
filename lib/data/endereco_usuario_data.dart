import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnderecoUsuario {
  final String id;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final String complemento;
  final bool padrao;

  const EnderecoUsuario({
    required this.id,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    this.complemento = '',
    this.padrao = false,
  });

  EnderecoUsuario copyWith({
    String? id,
    String? rua,
    String? numero,
    String? bairro,
    String? cidade,
    String? estado,
    String? cep,
    String? complemento,
    bool? padrao,
  }) {
    return EnderecoUsuario(
      id: id ?? this.id,
      rua: rua ?? this.rua,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      complemento: complemento ?? this.complemento,
      padrao: padrao ?? this.padrao,
    );
  }

  String get titulo => '$rua, $numero';
  String get subtitulo => '$bairro - $cidade/$estado';
  String get cepFormatado => 'CEP $cep';

  String get resumoPedido {
    if (complemento.trim().isEmpty) {
      return '$rua, $numero - $bairro, $cidade/$estado - CEP $cep';
    }

    return '$rua, $numero ($complemento) - $bairro, $cidade/$estado - CEP $cep';
  }

  Map<String, dynamic> toMap() {
    return {
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'complemento': complemento,
      'padrao': padrao,
    };
  }

  static EnderecoUsuario? fromDynamic(
    dynamic value, {
    required String id,
    bool? padraoFallback,
  }) {
    if (value == null || value is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(value);
    final rua = (map['rua'] ?? '').toString().trim();
    final numero = (map['numero'] ?? '').toString().trim();
    final bairro = (map['bairro'] ?? '').toString().trim();
    final cidade = (map['cidade'] ?? '').toString().trim();
    final estado = (map['estado'] ?? '').toString().trim();
    final cep = (map['cep'] ?? '').toString().trim();
    final complemento = (map['complemento'] ?? '').toString().trim();
    final padrao = map['padrao'] == true || (padraoFallback ?? false);

    if (rua.isEmpty ||
        numero.isEmpty ||
        bairro.isEmpty ||
        cidade.isEmpty ||
        estado.isEmpty ||
        cep.isEmpty) {
      return null;
    }

    return EnderecoUsuario(
      id: id,
      rua: rua,
      numero: numero,
      bairro: bairro,
      cidade: cidade,
      estado: estado,
      cep: cep,
      complemento: complemento,
      padrao: padrao,
    );
  }
}

class EnderecoUsuarioData {
  EnderecoUsuarioData._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>>? _usuarioDocRef() {
    final uid = _uid;
    if (uid == null) {
      return null;
    }
    return _firestore.collection('usuarios').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>>? _enderecosRef() {
    final uid = _uid;
    if (uid == null) {
      return null;
    }
    return _firestore.collection('usuarios').doc(uid).collection('enderecos');
  }

  static Future<void> _migrarEnderecoLegacySeNecessario() async {
    final userDoc = _usuarioDocRef();
    final colRef = _enderecosRef();
    if (userDoc == null || colRef == null) {
      return;
    }

    final jaTemEndereco = await colRef.limit(1).get();
    if (jaTemEndereco.docs.isNotEmpty) {
      return;
    }

    final userDocSnapshot = await userDoc.get();
    final data = userDocSnapshot.data();
    if (data == null) {
      return;
    }

    final legacy = EnderecoUsuario.fromDynamic(
      data['endereco'],
      id: '',
      padraoFallback: true,
    );
    if (legacy == null) {
      return;
    }

    await colRef.add({
      ...legacy.toMap(),
      'padrao': true,
      'criado_em': FieldValue.serverTimestamp(),
      'atualizado_em': FieldValue.serverTimestamp(),
    });

    await userDoc.set({
      'endereco': FieldValue.delete(),
      'atualizado_em': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static List<EnderecoUsuario> _ordenarEnderecos(List<EnderecoUsuario> list) {
    list.sort((a, b) {
      if (a.padrao == b.padrao) {
        return 0;
      }
      return a.padrao ? -1 : 1;
    });
    return list;
  }

  static Stream<List<EnderecoUsuario>> streamEnderecos() async* {
    final colRef = _enderecosRef();
    if (colRef == null) {
      yield const [];
      return;
    }

    await _migrarEnderecoLegacySeNecessario();

    yield* colRef.snapshots().map((snapshot) {
      final enderecos = snapshot.docs
          .map((doc) => EnderecoUsuario.fromDynamic(doc.data(), id: doc.id))
          .whereType<EnderecoUsuario>()
          .toList(growable: false);

      return _ordenarEnderecos(enderecos);
    });
  }

  static Future<List<EnderecoUsuario>> buscarEnderecos() async {
    final colRef = _enderecosRef();
    if (colRef == null) {
      return const [];
    }

    await _migrarEnderecoLegacySeNecessario();

    final snapshot = await colRef.get();
    final enderecos = snapshot.docs
        .map((doc) => EnderecoUsuario.fromDynamic(doc.data(), id: doc.id))
        .whereType<EnderecoUsuario>()
        .toList(growable: false);

    return _ordenarEnderecos(enderecos);
  }

  static Future<EnderecoUsuario?> buscarEnderecoPadrao() async {
    final enderecos = await buscarEnderecos();
    if (enderecos.isEmpty) {
      return null;
    }

    return enderecos.firstWhere((e) => e.padrao, orElse: () => enderecos.first);
  }

  static Future<void> salvarNovoEndereco(EnderecoUsuario endereco) async {
    final colRef = _enderecosRef();
    if (colRef == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final existentes = await buscarEnderecos();
    final definirComoPadrao = existentes.every((e) => !e.padrao);

    await colRef.add({
      ...endereco.toMap(),
      'padrao': definirComoPadrao,
      'criado_em': FieldValue.serverTimestamp(),
      'atualizado_em': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> atualizarEndereco(
    String enderecoId,
    EnderecoUsuario endereco,
  ) async {
    final colRef = _enderecosRef();
    if (colRef == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final docRef = colRef.doc(enderecoId);
    final docSnapshot = await docRef.get();
    final padraoAtual = docSnapshot.data()?['padrao'] == true;

    await docRef.set({
      ...endereco.toMap(),
      'padrao': padraoAtual,
      'atualizado_em': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> definirComoPadrao(String enderecoId) async {
    final colRef = _enderecosRef();
    if (colRef == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final snapshot = await colRef.get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'padrao': doc.id == enderecoId});
    }
    await batch.commit();
  }

  static Future<void> removerEndereco(String enderecoId) async {
    final colRef = _enderecosRef();
    if (colRef == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final docRef = colRef.doc(enderecoId);
    final docSnapshot = await docRef.get();
    final eraPadrao = docSnapshot.data()?['padrao'] == true;

    await docRef.delete();

    if (!eraPadrao) {
      return;
    }

    final restantes = await colRef.limit(1).get();
    if (restantes.docs.isEmpty) {
      return;
    }

    await restantes.docs.first.reference.set({
      'padrao': true,
      'atualizado_em': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

import 'package:flutter/foundation.dart';

class AppNotification {
  final String titulo;
  final String mensagem;
  final DateTime data;
  final NotificationOrderDetail? pedidoDetalhe;
  bool lida;

  AppNotification({
    required this.titulo,
    required this.mensagem,
    required this.data,
    this.pedidoDetalhe,
    this.lida = false,
  });
}

class NotificationOrderItem {
  final String productId;
  final String nome;
  final String imagem;
  final int quantidade;
  final double precoUnitario;

  const NotificationOrderItem({
    required this.productId,
    required this.nome,
    required this.imagem,
    required this.quantidade,
    required this.precoUnitario,
  });

  double get subtotal => precoUnitario * quantidade;
}

class NotificationOrderDetail {
  final List<NotificationOrderItem> itens;
  final double total;

  const NotificationOrderDetail({required this.itens, required this.total});
}

class NotificacoesData {
  static final List<AppNotification> _items = [];
  static final ValueNotifier<int> _version = ValueNotifier<int>(0);
  static final ValueNotifier<int> _unreadCount = ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _version;
  static ValueListenable<int> get unreadListenable => _unreadCount;

  static List<AppNotification> get items => List.unmodifiable(_items);
  static int get unreadCount => _unreadCount.value;

  static void _syncUnreadCount() {
    _unreadCount.value = _items.where((item) => !item.lida).length;
  }

  static void adicionar(AppNotification notification) {
    _items.insert(0, notification);
    _syncUnreadCount();
    _version.value++;
  }

  static void remover(AppNotification notification) {
    final removed = _items.remove(notification);
    if (!removed) return;

    _syncUnreadCount();
    _version.value++;
  }

  static void marcarTodasComoLidas() {
    var alterou = false;

    for (final item in _items) {
      if (!item.lida) {
        item.lida = true;
        alterou = true;
      }
    }

    if (alterou) {
      _syncUnreadCount();
      _version.value++;
    }
  }

  static void adicionarPedidoFinalizado({
    required int quantidadeItens,
    required double total,
    required List<NotificationOrderItem> itens,
  }) {
    final totalFormatado = total.toStringAsFixed(2).replaceAll('.', ',');
    final sufixo = quantidadeItens == 1 ? 'item' : 'itens';

    adicionar(
      AppNotification(
        titulo: 'Pedido finalizado',
        mensagem:
            'Seu pedido com $quantidadeItens $sufixo foi confirmado. Total: R\$ $totalFormatado.',
        data: DateTime.now(),
        pedidoDetalhe: NotificationOrderDetail(
          itens: List<NotificationOrderItem>.unmodifiable(itens),
          total: total,
        ),
      ),
    );
  }
}

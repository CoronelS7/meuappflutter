import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meu_app_flutter/data/notificacoes_data.dart';

enum PedidoEtapaEstado { concluida, atual, pendente }

class PedidoEtapa {
  final String titulo;
  final String descricao;
  final Duration inicioEm;

  const PedidoEtapa({
    required this.titulo,
    required this.descricao,
    required this.inicioEm,
  });
}

class PedidoRastreamento {
  final DateTime criadoEm;
  final NotificationOrderDetail detalhe;

  const PedidoRastreamento({required this.criadoEm, required this.detalhe});
}

class PedidoStatusData {
  PedidoStatusData._();

  static const List<PedidoEtapa> etapas = [
    PedidoEtapa(
      titulo: 'Aguardando preparo',
      descricao: 'Restaurante recebeu o pedido e esta organizando a cozinha.',
      inicioEm: Duration(seconds: 0),
    ),
    PedidoEtapa(
      titulo: 'Pedido em preparo',
      descricao: 'Seu pedido esta sendo preparado com todo cuidado.',
      inicioEm: Duration(seconds: 30),
    ),
    PedidoEtapa(
      titulo: 'Aguardando coleta do motoboy',
      descricao: 'Pedido pronto, aguardando retirada para entrega.',
      inicioEm: Duration(seconds: 60),
    ),
    PedidoEtapa(
      titulo: 'Pedido saiu para entrega',
      descricao: 'Motoboy retirou o pedido e iniciou a rota.',
      inicioEm: Duration(seconds: 90),
    ),
    PedidoEtapa(
      titulo: 'Pedido em deslocamento ao ponto de entrega',
      descricao: 'Entrega em andamento, chegando cada vez mais perto.',
      inicioEm: Duration(seconds: 120),
    ),
    PedidoEtapa(
      titulo: 'Pedido chegou',
      descricao: 'Motoboy chegou no local da entrega.',
      inicioEm: Duration(seconds: 150),
    ),
    PedidoEtapa(
      titulo: 'Pedido entregue',
      descricao: 'Entrega finalizada com sucesso.',
      inicioEm: Duration(seconds: 180),
    ),
    PedidoEtapa(
      titulo: 'Bom apetite',
      descricao: 'Tudo certo com seu pedido. Aproveite sua refeicao.',
      inicioEm: Duration(seconds: 210),
    ),
  ];

  static final ValueNotifier<int> _version = ValueNotifier<int>(0);
  static final ValueNotifier<int> _shortcutVersion = ValueNotifier<int>(0);
  static PedidoRastreamento? _pedidoAtual;
  static Timer? _ticker;
  static int _ultimoIndiceEtapaEmitido = -1;

  static ValueListenable<int> get listenable => _version;
  static ValueListenable<int> get shortcutListenable => _shortcutVersion;
  static PedidoRastreamento? get pedidoAtual => _pedidoAtual;
  static bool get temPedidoAtivo => _pedidoAtual != null;
  static int get totalEtapas => etapas.length;

  static void iniciarRastreamento({
    required List<NotificationOrderItem> itens,
    required double total,
  }) {
    _pedidoAtual = PedidoRastreamento(
      criadoEm: DateTime.now(),
      detalhe: NotificationOrderDetail(
        itens: List<NotificationOrderItem>.unmodifiable(itens),
        total: total,
      ),
    );
    _ultimoIndiceEtapaEmitido = 0;
    _emit();
    _emitShortcut();
    _iniciarTicker();
  }

  static void encerrarRastreamento() {
    _ticker?.cancel();
    _ticker = null;
    _pedidoAtual = null;
    _ultimoIndiceEtapaEmitido = -1;
    _emit();
    _emitShortcut();
  }

  static int indiceEtapaAtual({DateTime? referencia}) {
    if (_pedidoAtual == null) {
      return -1;
    }

    final momentoAtual = referencia ?? DateTime.now();
    final tempoDecorrido = momentoAtual.difference(_pedidoAtual!.criadoEm);

    for (var i = etapas.length - 1; i >= 0; i--) {
      if (!tempoDecorrido.isNegative && tempoDecorrido >= etapas[i].inicioEm) {
        return i;
      }
    }

    return 0;
  }

  static PedidoEtapaEstado estadoDaEtapa(int index, {DateTime? referencia}) {
    final etapaAtual = indiceEtapaAtual(referencia: referencia);
    if (etapaAtual < 0) {
      return PedidoEtapaEstado.pendente;
    }

    if (index < etapaAtual) {
      return PedidoEtapaEstado.concluida;
    }

    if (index == etapaAtual) {
      return PedidoEtapaEstado.atual;
    }

    return PedidoEtapaEstado.pendente;
  }

  static bool get pedidoConcluido => indiceEtapaAtual() >= etapas.length - 1;

  static double progresso({DateTime? referencia}) {
    final etapaAtual = indiceEtapaAtual(referencia: referencia);
    if (etapaAtual < 0) {
      return 0;
    }
    return (etapaAtual + 1) / etapas.length;
  }

  static Duration tempoRestante({DateTime? referencia}) {
    if (_pedidoAtual == null) {
      return Duration.zero;
    }

    final momentoAtual = referencia ?? DateTime.now();
    final tempoDecorrido = momentoAtual.difference(_pedidoAtual!.criadoEm);
    final tempoTotal = etapas.last.inicioEm;
    final restante = tempoTotal - tempoDecorrido;

    return restante.isNegative ? Duration.zero : restante;
  }

  static String formatarDuracao(Duration duration) {
    final minutos = duration.inMinutes.toString().padLeft(2, '0');
    final segundos = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  static void _iniciarTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pedidoAtual == null) {
        timer.cancel();
        _ticker = null;
        return;
      }

      _emit();
      final indiceAtual = indiceEtapaAtual();
      if (indiceAtual != _ultimoIndiceEtapaEmitido) {
        _ultimoIndiceEtapaEmitido = indiceAtual;
        _emitShortcut();
      }

      if (pedidoConcluido) {
        timer.cancel();
        _ticker = null;
      }
    });
  }

  static void _emit() {
    _version.value++;
  }

  static void _emitShortcut() {
    _shortcutVersion.value++;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/notificacoes_data.dart';
import 'package:meu_app_flutter/data/pedido_status_data.dart';

class PedidoStatusScreen extends StatelessWidget {
  const PedidoStatusScreen({super.key});

  String _formatarReais(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
        title: const Text(
          'Status do pedido',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: PedidoStatusData.listenable,
        builder: (context, version, child) {
          final pedido = PedidoStatusData.pedidoAtual;
          if (pedido == null) {
            return const Center(
              child: Text(
                'Nenhum pedido em andamento.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: AppColors.gray500,
                ),
              ),
            );
          }

          final etapaAtualIndex = PedidoStatusData.indiceEtapaAtual();
          final etapaAtual = PedidoStatusData.etapas[etapaAtualIndex];
          final progresso = PedidoStatusData.progresso();
          final tempoRestante = PedidoStatusData.tempoRestante();
          final tempoRestanteTexto = PedidoStatusData.formatarDuracao(
            tempoRestante,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary600, AppColors.primary300],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Acompanhamento em tempo real',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.17),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delivery_dining_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      etapaAtual.titulo,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      etapaAtual.descricao,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Etapa ${etapaAtualIndex + 1}/${PedidoStatusData.totalEtapas}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          PedidoStatusData.pedidoConcluido
                              ? 'Concluido'
                              : 'Tempo estimado: $tempoRestanteTexto',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Etapas do pedido',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(PedidoStatusData.etapas.length, (index) {
                final etapa = PedidoStatusData.etapas[index];
                final estado = PedidoStatusData.estadoDaEtapa(index);
                final isLast = index == PedidoStatusData.etapas.length - 1;

                final bool concluida = estado == PedidoEtapaEstado.concluida;
                final bool atual = estado == PedidoEtapaEstado.atual;

                final Color bulletColor = concluida || atual
                    ? AppColors.primary300
                    : AppColors.gray300;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: concluida
                                  ? AppColors.primary300
                                  : atual
                                  ? AppColors.primary100
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: bulletColor, width: 2),
                            ),
                            child: Icon(
                              concluida
                                  ? Icons.check
                                  : atual
                                  ? Icons.radio_button_checked
                                  : Icons.circle_outlined,
                              size: 14,
                              color: concluida
                                  ? Colors.white
                                  : atual
                                  ? AppColors.primary600
                                  : AppColors.gray300,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 42,
                              color: concluida || atual
                                  ? AppColors.primary200
                                  : AppColors.gray200,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: atual ? AppColors.primary100 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: atual
                                ? AppColors.primary200
                                : AppColors.gray200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              etapa.titulo,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: atual
                                    ? AppColors.primary600
                                    : AppColors.gray700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              etapa.descricao,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.gray500,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              _ResumoPedidoCard(
                detalhe: pedido.detalhe,
                formatarReais: _formatarReais,
              ),
              if (PedidoStatusData.pedidoConcluido) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary300,
                    ),
                    onPressed: () {
                      PedidoStatusData.encerrarRastreamento();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Encerrar acompanhamento',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ResumoPedidoCard extends StatelessWidget {
  final NotificationOrderDetail detalhe;
  final String Function(double) formatarReais;

  const _ResumoPedidoCard({required this.detalhe, required this.formatarReais});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do pedido',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          ...detalhe.itens
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantidade}x ${item.nome}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                      Text(
                        formatarReais(item.subtotal),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (detalhe.itens.length > 3)
            Text(
              '+ ${detalhe.itens.length - 3} item(ns)',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.gray500,
                fontSize: 12,
              ),
            ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray700,
                ),
              ),
              Text(
                formatarReais(detalhe.total),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

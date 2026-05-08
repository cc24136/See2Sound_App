import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
    const HomeScreen({super.key});

    static const Color backgroundColor = Color(0xFF202020);
    static const Color headerColor = Color(0xFF1B1B1B);
    static const Color cardColor = Color(0xFF303030);
    static const Color purpleColor = Color(0xFF7B2CFF);
    static const Color textColor = Color(0xFFF2F2F2);
    static const Color mutedTextColor = Color(0xFFCFCFCF);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        backgroundColor: backgroundColor,
        body: Column(
            children: [
            const _Header(),

            Expanded(
                child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        const Text(
                        'Bem-vindo ao See2Sound',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                        ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                        'Importe um novo arquivo para gerar uma nova\naudiodescrição',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 14,
                            height: 1.2,
                        ),
                        ),

                        const SizedBox(height: 26),

                        const _ImportCard(),
                    ],
                    ),
                ),
                ),
            ),
            ],
        ),
        );
    }
    }

    class _Header extends StatelessWidget {
    const _Header();

    static const Color headerColor = Color(0xFF1B1B1B);
    static const Color borderColor = Color(0xFF333333);
    static const Color purpleColor = Color(0xFF8A35FF);

    @override
    Widget build(BuildContext context) {
        return Container(
        height: 42,
        decoration: const BoxDecoration(
            color: headerColor,
            border: Border(
            bottom: BorderSide(
                color: borderColor,
                width: 1,
            ),
            ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
            children: [
            Image.asset(
                'assets/images/logo.png',
                width: 40,
                height: 26,
                fit: BoxFit.contain,
            ),

            const SizedBox(width: 8),

            const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                    'See2Sound',
                    style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    ),
                ),
                SizedBox(height: 2),
                Text(
                    'ver 0.1',
                    style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 8,
                    height: 1,
                    ),
                ),
                ],
            ),

            const Spacer(),

            TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                foregroundColor: purpleColor,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text(
                'Gerar audiodescrição',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                ),
                ),
            ),

            const SizedBox(width: 16),

            TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text(
                'Suas audiodescrições',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                ),
                ),
            ),

            const SizedBox(width: 24),

            IconButton(
                onPressed: () {},
                icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 24,
                ),
            ),
            ],
        ),
        );
    }
}

class _ImportCard extends StatelessWidget {
    const _ImportCard();

    static const Color cardColor = Color(0xFF303030);
    static const Color purpleColor = Color(0xFF7B2CFF);

    @override
    Widget build(BuildContext context) {
        return InkWell(
        onTap: () {
            // Depois você coloca aqui o seletor de arquivo.
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
            width: 465,
            height: 248,
            decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
                BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 0),
                ),
            ],
            ),
            child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(
                Icons.drive_folder_upload_outlined,
                color: purpleColor,
                size: 42,
                ),

                SizedBox(height: 12),

                Text(
                'Importar Arquivo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                ),
                ),
            ],
            ),
        ),
        );
    }
}
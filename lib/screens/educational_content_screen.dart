import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/educational_article_model.dart';
import '../providers/app_manager_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_section_header.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class EducationalContentScreen extends StatefulWidget {
  const EducationalContentScreen({Key? key}) : super(key: key);

  @override
  State<EducationalContentScreen> createState() =>
      _EducationalContentScreenState();
}

class _EducationalContentScreenState extends State<EducationalContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppManagerProvider>().refreshEducationalContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();
    final items = manager.articles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: manager.refreshEducationalContent,
        color: _silverAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          children: <Widget>[
            const SizedBox(height: 6),
            const AppSectionHeader(title: 'المحتوى التعليمي'),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const _EmptyEducationalState()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: items
                        .map(
                          (article) => SizedBox(
                            width: cardWidth,
                            child: _LearningModuleCard(article: article),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyEducationalState extends StatelessWidget {
  const _EmptyEducationalState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardLight),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.menu_book_outlined,
            color: AppColors.textSecondary,
            size: 34,
          ),
          SizedBox(height: 8),
          Text(
            'لا يوجد محتوى تعليمي متاح حاليًا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningModuleCard extends StatelessWidget {
  const _LearningModuleCard({required this.article});

  final EducationalArticleSummary article;

  @override
  Widget build(BuildContext context) {
    final publishedLabel = _formatPublishedDate(article.publishedAt);
    final reading = article.readingMinutes <= 0 ? 3 : article.readingMinutes;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EducationalArticleDetailsScreen(slug: article.slug),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cardLight,
              width: 1.1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(17)),
                child: SizedBox(
                  height: 158,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (article.coverImageUrl != null &&
                          article.coverImageUrl!.isNotEmpty)
                        Image.network(
                          article.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderCover(),
                        )
                      else
                        _placeholderCover(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _chip(
                          article.isFeatured ? 'مميز' : 'درس تعليمي',
                          article.isFeatured
                              ? _silverAccent.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.88),
                          article.isFeatured
                              ? Colors.black
                              : const Color(0xFF222222),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: _chip(
                                '$reading دقائق قراءة',
                                Colors.black.withValues(alpha: 0.48),
                                Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _chip(
                                publishedLabel,
                                Colors.black.withValues(alpha: 0.48),
                                Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      article.excerpt.trim().isEmpty
                          ? 'افتح المحتوى لقراءة التفاصيل الكاملة.'
                          : article.excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: <Widget>[
                        Icon(
                          Icons.play_circle_fill_rounded,
                          size: 18,
                          color: _silverAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ابدأ القراءة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _silverAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            _silverAccent.withValues(alpha: 0.48),
            const Color(0xFF222222),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.lightbulb_outline_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class EducationalArticleDetailsScreen extends StatefulWidget {
  const EducationalArticleDetailsScreen({Key? key, required this.slug})
      : super(key: key);

  final String slug;

  @override
  State<EducationalArticleDetailsScreen> createState() =>
      _EducationalArticleDetailsScreenState();
}

class _EducationalArticleDetailsScreenState
    extends State<EducationalArticleDetailsScreen> {
  EducationalArticleDetail? _article;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final manager = context.read<AppManagerProvider>();
    final article = await manager.getEducationalArticleDetail(widget.slug);
    if (!mounted) return;
    setState(() {
      _article = article;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _silverAccent,
        iconTheme: const IconThemeData(color: _silverAccent),
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _silverAccent,
        ),
        title: const Text('المحتوى التعليمي'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _article == null
              ? const Center(
                  child: Text(
                    'تعذر تحميل المحتوى.',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: <Widget>[
                    _DetailsHero(article: _article!),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _metaChip(
                                '${_article!.readingMinutes <= 0 ? 3 : _article!.readingMinutes} دقائق قراءة',
                              ),
                              _metaChip(
                                  _formatPublishedDate(_article!.publishedAt)),
                              if (_article!.isFeatured) _metaChip('محتوى مميز'),
                            ],
                          ),
                          if ((_article!.excerpt ?? '')
                              .trim()
                              .isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              _article!.excerpt!.trim(),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                height: 1.65,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          ..._buildBodyParagraphs(_article!.body),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Widget> _buildBodyParagraphs(String body) {
    final cleaned = body.trim();
    if (cleaned.isEmpty) {
      return const <Widget>[
        Text(
          'لا يوجد نص متاح لهذا المحتوى.',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }

    final paragraphs = cleaned
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      paragraphs.add(cleaned);
    }

    return paragraphs
        .map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.8,
              ),
            ),
          ),
        )
        .toList();
  }
}

class _DetailsHero extends StatelessWidget {
  const _DetailsHero({required this.article});

  final EducationalArticleDetail article;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (article.coverImageUrl != null &&
                  article.coverImageUrl!.isNotEmpty)
                Image.network(
                  article.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _heroFallback(),
                )
              else
                _heroFallback(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF343434), Color(0xFF171717)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school_outlined,
          color: Colors.white70,
          size: 42,
        ),
      ),
    );
  }
}

String _formatPublishedDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 'بدون تاريخ';
  }

  final parsed = DateTime.tryParse(raw.trim())?.toLocal();
  if (parsed == null) {
    return 'بدون تاريخ';
  }

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  return '$day/$month/$year';
}

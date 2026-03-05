class EducationalArticleSummary {
  final int id;
  final String title;
  final String slug;
  final String excerpt;
  final String? coverImageUrl;
  final String? publishedAt;
  final int readingMinutes;
  final bool isFeatured;

  const EducationalArticleSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.coverImageUrl,
    required this.publishedAt,
    required this.readingMinutes,
    required this.isFeatured,
  });

  factory EducationalArticleSummary.fromJson(Map<String, dynamic> json) {
    return EducationalArticleSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      excerpt: (json['excerpt'] ?? '').toString(),
      coverImageUrl: json['cover_image_url']?.toString(),
      publishedAt: json['published_at']?.toString(),
      readingMinutes: (json['reading_minutes'] as num?)?.toInt() ?? 3,
      isFeatured: json['is_featured'] == true,
    );
  }
}

class EducationalArticleDetail {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String body;
  final String? coverImageUrl;
  final String? publishedAt;
  final int readingMinutes;
  final bool isFeatured;

  const EducationalArticleDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.body,
    required this.coverImageUrl,
    required this.publishedAt,
    required this.readingMinutes,
    required this.isFeatured,
  });

  factory EducationalArticleDetail.fromJson(Map<String, dynamic> json) {
    return EducationalArticleDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      excerpt: json['excerpt']?.toString(),
      body: (json['body'] ?? '').toString(),
      coverImageUrl: json['cover_image_url']?.toString(),
      publishedAt: json['published_at']?.toString(),
      readingMinutes: (json['reading_minutes'] as num?)?.toInt() ?? 3,
      isFeatured: json['is_featured'] == true,
    );
  }
}

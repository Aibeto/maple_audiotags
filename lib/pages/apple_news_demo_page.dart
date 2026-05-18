import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 主题常量
// ─────────────────────────────────────────────────────────────────────────────

/// 新闻红色主题色
const _kNewsRed = Color(0xFFFF2D55);

/// 直播徽章颜色
const _kLiveBadge = Color(0xFFFF3B30);

/// 背景颜色（黑色）
const _kBackground = Color(0xFF000000);

/// 卡片背景颜色
const _kCardBackground = Color(0xFF1C1C1E);

/// 分隔线颜色
const _kSeparator = Color(0xFF38383A);

// ─────────────────────────────────────────────────────────────────────────────
// 数据模型
// ─────────────────────────────────────────────────────────────────────────────

/// 文章数据模型
class _Article {
  /// 构造函数
  const _Article({
    required this.headline,
    required this.publication,
    required this.imageAsset,
    this.isLive = false,
    this.hasTopStoriesBadge = false,
    this.moreCoverage = false,
  });

  /// 新闻标题
  final String headline;

  /// 发布机构
  final String publication;

  /// 图片资源路径
  final String imageAsset;

  /// 是否是直播新闻
  final bool isLive;

  /// 是否有头条故事徽章
  final bool hasTopStoriesBadge;

  /// 是否有更多报道
  final bool moreCoverage;
}

// ─────────────────────────────────────────────────────────────────────────────
// 模拟数据
// ─────────────────────────────────────────────────────────────────────────────

/// 头条故事列表
const _kTopStories = [
  _Article(
    headline:
        'Tehran warns US over Strait of Hormuz threat; Netanyahu suggests Israel helped rescue airman',
    publication: 'The Guardian',
    imageAsset: 'assets/news_images/tehran_guardian.jpg',
    // isLive: true,
    hasTopStoriesBadge: true,
    moreCoverage: true,
  ),
  _Article(
    headline:
        'Markets surge after Fed signals three rate cuts this year despite persistent inflation',
    publication: 'The Wall Street Journal',
    imageAsset: 'assets/news_images/markets_wsj.jpg',
    moreCoverage: true,
  ),
  _Article(
    headline:
        'Apple announces spatial computing breakthrough at WWDC, Vision Pro 2 coming this fall',
    publication: 'Bloomberg',
    imageAsset: 'assets/news_images/apple_bloomberg.jpg',
  ),
];

/// 更多文章列表
const _kMoreArticles = [
  _Article(
    headline:
        'Scientists discover potential link between gut microbiome and Alzheimer\'s disease risk',
    publication: 'Nature',
    imageAsset: 'assets/news_images/science_nature.jpg',
  ),
  _Article(
    headline:
        'UEFA Champions League: Real Madrid face Arsenal in stunning semi-final clash',
    publication: 'BBC Sport',
    imageAsset: 'assets/news_images/soccer_bbc.jpg',
  ),
  _Article(
    headline:
        'Climate summit reaches historic agreement on carbon emissions targets ahead of 2030 deadline',
    publication: 'Reuters',
    imageAsset: 'assets/news_images/climate_reuters.jpg',
    isLive: true,
  ),
  _Article(
    headline:
        'New AI model writes code faster than senior engineers, raising questions about the future of work',
    publication: 'MIT Technology Review',
    imageAsset: 'assets/news_images/ai_mit.jpg',
  ),
  _Article(
    headline:
        'SpaceX Starship completes first fully successful orbital flight and ocean landing',
    publication: 'The Verge',
    imageAsset: 'assets/news_images/spacex_verge.jpg',
  ),
];

/// 话题分类数据模型
class _TopicCategory {
  /// 构造函数
  const _TopicCategory({
    required this.name,
    required this.color,
    required this.imageAsset,
  });

  /// 分类名称
  final String name;

  /// 分类主题色
  final Color color;

  /// 图片资源路径
  final String imageAsset;
}

/// 话题分类列表
const _kTopics = [
  _TopicCategory(
    name: 'Sport',
    color: Color(0xFF34C759),
    imageAsset: 'assets/news_images/topic_sport.jpg',
  ),
  _TopicCategory(
    name: 'Entertainment',
    color: Color(0xFFFF3B30),
    imageAsset: 'assets/news_images/topic_entertainment.jpg',
  ),
  _TopicCategory(
    name: 'Business',
    color: Color(0xFF007AFF),
    imageAsset: 'assets/news_images/topic_business.jpg',
  ),
  _TopicCategory(
    name: 'Politics',
    color: Color(0xFF3A3A3C),
    imageAsset: 'assets/news_images/topic_politics.jpg',
  ),
  _TopicCategory(
    name: 'Food',
    color: Color(0xFFFFCC02),
    imageAsset: 'assets/news_images/topic_food.jpg',
  ),
  _TopicCategory(
    name: 'Health',
    color: Color(0xFFFF9500),
    imageAsset: 'assets/news_images/topic_health.jpg',
  ),
  _TopicCategory(
    name: 'Lifestyle',
    color: Color(0xFF30B0C7),
    imageAsset: 'assets/news_images/topic_lifestyle.jpg',
  ),
  _TopicCategory(
    name: 'Science',
    color: Color(0xFFAF52DE),
    imageAsset: 'assets/news_images/topic_science.jpg',
  ),
  _TopicCategory(
    name: 'Climate',
    color: Color(0xFFBF5AF2),
    imageAsset: 'assets/news_images/topic_climate.jpg',
  ),
  _TopicCategory(
    name: 'Cars',
    color: Color(0xFF636366),
    imageAsset: 'assets/news_images/topic_cars.jpg',
  ),
  _TopicCategory(
    name: 'Home & Garden',
    color: Color(0xFF34C759),
    imageAsset: 'assets/news_images/topic_garden.jpg',
  ),
  _TopicCategory(
    name: 'Travel',
    color: Color(0xFF30B0C7),
    imageAsset: 'assets/news_images/topic_travel.jpg',
  ),
];

/// 分类标签列表
const _kCategories = [
  'Sport',
  'Business',
  'Food',
  'Entertainment',
  'Health',
  'Science',
  'Climate',
];

// ─────────────────────────────────────────────────────────────────────────────
// 主屏幕
// ─────────────────────────────────────────────────────────────────────────────

/// Apple News 主页面组件
class AppleNewsHomeScreen extends StatefulWidget {
  /// 构造函数
  const AppleNewsHomeScreen({super.key});

  @override
  State<AppleNewsHomeScreen> createState() => _AppleNewsHomeScreenState();
}

class _AppleNewsHomeScreenState extends State<AppleNewsHomeScreen> {
  /// 是否正在搜索
  bool _isSearching = false;

  /// 搜索框是否获得焦点（true = 键盘可见）
  bool _searchFieldFocused = false;

  /// 当前选中的标签页索引（0=Today, 1=News+, 2=Audio, 3=Following）
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    // Android 三按钮导航需要我们将底部栏推到不透明按钮上方
    // 在 iOS 和手势导航 Android 上，viewPaddingOf 返回 0，因此不应用偏移
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final sysBottom = isIOS ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kBackground,
      extendBody: true, // 内容流到底部栏后面
      // 保持 false，以便底部栏管理自己的键盘布局
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          if (_searchFieldFocused) {
            // 与 DismissPill 修复一致：使用 primaryFocus?.unfocus()，
            // 以便完全释放 FocusNode，而不仅仅是移动到作用域父级
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              // 三种主体状态：
              //   1. 未搜索        → 今日文章视图
              //   2. 搜索中 + 未聚焦 → 话题浏览（可搜索内容）
              //   3. 搜索中 + 聚焦   → "无最近搜索"空状态
              child: !_isSearching
                  ? _buildTodayView(key: const ValueKey('today'))
                  : _searchFieldFocused
                  ? _buildNoRecentSearches(key: const ValueKey('no-recent'))
                  : _buildSearchBrowseView(
                      key: const ValueKey('search-browse'),
                    ),
            ),
          ],
        ),
      ),
      // ── 玻璃效果可搜索底部栏 ─────────────────────────────────────────
      // 包裹在 Padding 中以清除 Android 三按钮导航（sysBottom > 0）
      // 在 iOS 和手势导航 Android 上，sysBottom 为 0，因此不应用偏移
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: sysBottom),
        child: GlassSearchableBottomBar(
          selectedIndex: _selectedTab,
          isSearchActive: _isSearching,
          onTabSelected: (index) => setState(() {
            _selectedTab = index;
            _isSearching = false;
          }),
          selectedIconColor: Color.fromRGBO(255, 90, 130, 1),
          unselectedIconColor: Colors.white.withValues(alpha: 0.9),
          labelFontSize: 10,
          iconSize: 28,
          iconLabelSpacing: 0,
          // 中性磨砂玻璃效果的药丸状指示器。AnimatedGlassIndicator 现在直接渲染此值，没有任何隐藏的乘数
          indicatorColor: Colors.white.withValues(alpha: 0.20),
          quality: GlassQuality.premium,
          interactionBehavior:
              GlassInteractionBehavior.full, // 或 .none / .glowOnly / .scaleOnly
          glassSettings: LiquidGlassSettings(
            glassColor: const Color(0xAA1C1C1E),
            thickness: 30,
            blur: 2,
            chromaticAberration: .01,
            lightAngle: GlassDefaults.lightAngle,
            lightIntensity: .5,
            ambientStrength: 0,
            refractiveIndex: 1.2,
            saturation: 1.2,
            specularSharpness: GlassSpecularSharpness.medium,
          ),
          // ── 搜索栏配置 ───────────────────────────────────────────────
          searchConfig: GlassSearchBarConfig(
            hintText: 'Apple News',
            onSearchToggle: (active) => setState(() {
              _isSearching = active;
              // 搜索关闭时重置焦点状态，以便下次打开时是全新的
              if (!active) _searchFieldFocused = false;
            }),
            onSearchFocusChanged: (focused) =>
                setState(() => _searchFieldFocused = focused),
            searchIconColor: Colors.white.withValues(alpha: 0.9),
            textInputAction: TextInputAction.search,
            autoFocusOnExpand: false,
            showsCancelButton: true,
            onMicTap: () {},
          ),
          tabs: [
            GlassBottomBarTab(
              label: 'Today',
              icon: const Icon(CupertinoIcons.house),
              activeIcon: const Icon(CupertinoIcons.house_fill),
            ),
            GlassBottomBarTab(
              label: 'News+',
              icon: const Icon(CupertinoIcons.news_solid),
              activeIcon: const Icon(CupertinoIcons.news_solid),
            ),
            GlassBottomBarTab(
              label: 'Audio',
              icon: const Icon(CupertinoIcons.headphones),
            ),
            GlassBottomBarTab(
              label: 'Following',
              icon: const Icon(
                CupertinoIcons.rectangle_fill_on_rectangle_angled_fill,
              ),
            ),
          ],
        ),
      ), // Padding
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 今日视图
  // ─────────────────────────────────────────────────────────────────────────

  /// 构建今日视图
  Widget _buildTodayView({Key? key}) {
    return CustomScrollView(
      key: key,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top + 8),
        ),
        SliverToBoxAdapter(child: _buildNewsHeader()),
        SliverToBoxAdapter(child: _buildCategoryChips()),
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Top Stories',
            'Chosen by the Apple News editors.',
          ),
        ),
        SliverToBoxAdapter(child: _buildHeroArticleCard(_kTopStories[0])),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildCompactArticleCard(_kTopStories[index + 1]),
            childCount: _kTopStories.length - 1,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSectionHeader('Trending Stories', null),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCompactArticleCard(_kMoreArticles[index]),
            childCount: _kMoreArticles.length,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 100),
        ),
      ],
    );
  }

  /// 构建新闻标题栏
  Widget _buildNewsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.apple, color: Colors.white, size: 28),
                  SizedBox(width: 4),
                  Text(
                    'News',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '6 April',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _kNewsRed,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Try News+ Free',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类标签行
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) =>
            _CategoryChip(label: _kCategories[index]),
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionHeader(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _kNewsRed,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 构建主要文章卡片（大图展示）
  Widget _buildHeroArticleCard(_Article article) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(article.imageAsset, fit: BoxFit.cover),
            ),
            Container(
              color: _kCardBackground,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.isLive) _buildLiveBadge(),
                  if (article.isLive) const SizedBox(height: 8),
                  Text(
                    article.publication,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (article.moreCoverage) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: _kSeparator),
                    const SizedBox(height: 10),
                    Text(
                      'MORE COVERAGE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建紧凑文章卡片（小图展示）
  Widget _buildCompactArticleCard(_Article article) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: _kCardBackground,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.isLive) ...[
                      _buildLiveBadge(),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      article.publication,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.headline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (article.moreCoverage) ...[
                      const SizedBox(height: 10),
                      Text(
                        'MORE COVERAGE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  article.imageAsset,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建直播徽章
  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kLiveBadge,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Live',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 搜索视图
  // ─────────────────────────────────────────────────────────────────────────

  /// 状态 2 — 搜索中但键盘未打开：显示话题浏览网格
  Widget _buildSearchBrowseView({Key? key}) {
    return CustomScrollView(
      key: key,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top + 8),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Apple News 标识行 — 符合参考截图
                const Row(
                  children: [
                    Icon(Icons.apple, color: Colors.white, size: 22),
                    SizedBox(width: 4),
                    Text(
                      'News',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Search',
                  style: TextStyle(
                    color: Color(0xFF8E8E93), // iOS 次要标签灰色
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.paddingOf(context).bottom + 100,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _TopicCard(topic: _kTopics[index]),
              childCount: _kTopics.length,
            ),
          ),
        ),
      ],
    );
  }

  /// 状态 3 — 搜索中 + 键盘可见：显示"无最近搜索"
  Widget _buildNoRecentSearches({Key? key}) {
    // viewInsetsOf 每帧都提供键盘高度（不需要 setState）
    // 将其添加到外部容器的底部 padding 中，使 Center() 将其内容居中在键盘上方的剩余空间中
    // — 这正是 Apple News 所做的。额外的 50 为浮动栏留出空间
    final keyboardH = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      key: key,
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardH + 50),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.search,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Recent Searches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your recent searches will appear here.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Apple News 演示页面
class AppleNewsDemoPage extends StatelessWidget {
  /// 构造函数
  const AppleNewsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWidgets.wrap(
      child: Stack(
        children: [
          const AppleNewsHomeScreen(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
      adaptiveQuality: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 子组件
// ─────────────────────────────────────────────────────────────────────────────

/// 分类标签组件
class _CategoryChip extends StatelessWidget {
  /// 构造函数
  const _CategoryChip({required this.label});

  /// 标签文本
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 完整的图片支持话题卡片 — 符合 iOS 26 Apple News 搜索网格
class _TopicCard extends StatelessWidget {
  /// 构造函数
  const _TopicCard({required this.topic});

  /// 话题分类数据
  final _TopicCategory topic;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: topic.color),
          // 图片部分透明，以便分类颜色占主导地位
          Opacity(
            opacity: 0.45,
            child: Image.asset(topic.imageAsset, fit: BoxFit.cover),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            right: 12,
            child: Text(
              topic.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final double progress;
  final String category;
  final int totalLessons;
  final int completedLessons;
  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.category,
    required this.totalLessons,
    required this.completedLessons,
  });
}
final List<CourseModel> sampleCourses = [
  CourseModel(
    id: '1',
    title: 'Web Development',
    description: 'Learn HTML, CSS, JavaScript and modern frameworks.',
    icon: '🌐',
    progress: 0.65,
    category: 'Tech',
    totalLessons: 40,
    completedLessons: 26,
  ),
  CourseModel(
    id: '2',
    title: 'App Development',
    description: 'Build Android & iOS apps with Flutter.',
    icon: '📱',
    progress: 0.40,
    category: 'Tech',
    totalLessons: 35,
    completedLessons: 14,
  ),
  CourseModel(
    id: '3',
    title: 'Artificial Intelligence',
    description: 'Machine Learning, Deep Learning & AI fundamentals.',
    icon: '🤖',
    progress: 0.20,
    category: 'Tech',
    totalLessons: 50,
    completedLessons: 10,
  ),
  CourseModel(
    id: '4',
    title: 'Data Science',
    description: 'Data analysis, visualization and statistics.',
    icon: '📊',
    progress: 0.55,
    category: 'Tech',
    totalLessons: 30,
    completedLessons: 17,
  ),
  CourseModel(
    id: '5',
    title: 'UI/UX Design',
    description: 'Design beautiful and user-friendly interfaces.',
    icon: '🎨',
    progress: 0.30,
    category: 'Design',
    totalLessons: 25,
    completedLessons: 8,
  ),
  CourseModel(
    id: '6',
    title: 'Cybersecurity',
    description: 'Protect systems and networks from cyber threats.',
    icon: '🔐',
    progress: 0.10,
    category: 'Tech',
    totalLessons: 45,
    completedLessons: 5,
  ),
];

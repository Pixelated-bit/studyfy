class StudyGuide {
  final String subject;
  final String summary;
  final List<String> methods;

  const StudyGuide({
    required this.subject,
    required this.summary,
    required this.methods,
  });
}

const StudyGuide _general = StudyGuide(
  subject: 'General',
  summary: 'These methods work for almost any subject.',
  methods: [
    'Active recall: close your notes and write down everything you remember, then check what you missed.',
    'Spaced repetition: review the material after 1 day, 3 days, 1 week and 2 weeks instead of cramming.',
    'Study in focused blocks of 25 to 50 minutes, with a 5 to 10 minute break between them.',
    'Teach it: explain the topic out loud as if to a friend. Gaps in your explanation show what to revisit.',
    'Start with the hardest topic while your energy is highest.',
    'Put your phone out of reach while studying.',
  ],
);

const List<MapEntry<List<String>, StudyGuide>> _guides = [
  MapEntry(
    ['math', 'maths', 'mathematics', 'algebra', 'calculus', 'geometry', 'statistics'],
    StudyGuide(
      subject: 'Mathematics',
      summary: 'Maths is learned by doing, not by reading.',
      methods: [
        'Practise problems every day. Reading worked examples is not enough; solve them yourself first.',
        'Cover the solution, attempt the problem, then compare. Note exactly where your method differed.',
        'Keep an error log: write each mistake and the rule that fixes it, and review it weekly.',
        'Learn why a formula works, not just how to use it. Try deriving it once.',
        'Mix topics in one session (interleaving) so you learn to choose the right method.',
        'Do timed past-paper questions as exams get closer.',
      ],
    ),
  ),
  MapEntry(
    ['physics', 'mechanics'],
    StudyGuide(
      subject: 'Physics',
      summary: 'Physics combines concepts with problem solving.',
      methods: [
        'Draw a diagram for every problem and label the known and unknown quantities.',
        'Write the relevant formulas before substituting numbers, and check your units.',
        'Explain each concept in plain words before you attempt calculations.',
        'Practise many varied problems. Each one teaches a slightly different pattern.',
        'Estimate the answer first so you can tell whether your result is sensible.',
      ],
    ),
  ),
  MapEntry(
    ['chemistry'],
    StudyGuide(
      subject: 'Chemistry',
      summary: 'Chemistry mixes memorisation with understanding of patterns.',
      methods: [
        'Use flashcards for definitions, reactions and the periodic table trends.',
        'Practise balancing equations and mole calculations repeatedly.',
        'Group reactions by type and learn the pattern, not each reaction separately.',
        'Draw mechanisms and structures from memory, then check them.',
        'Review weekly using spaced repetition, since chemistry builds on earlier topics.',
      ],
    ),
  ),
  MapEntry(
    ['biology', 'bio'],
    StudyGuide(
      subject: 'Biology',
      summary: 'Biology has a lot of terms and connected processes.',
      methods: [
        'Redraw diagrams (cells, organs, cycles) from memory and label them.',
        'Use flashcards for key terms and review them with spaced repetition.',
        'Link processes together in a concept map to see how systems connect.',
        'Explain each process step by step out loud.',
        'Answer past exam questions to learn how to phrase answers precisely.',
      ],
    ),
  ),
  MapEntry(
    ['history', 'geography', 'social studies', 'civics', 'economics'],
    StudyGuide(
      subject: 'History and social subjects',
      summary: 'Focus on causes, effects and connections, not just dates.',
      methods: [
        'Build a timeline and add causes and consequences to each event.',
        'For each topic ask: what happened, why, and what changed as a result?',
        'Practise writing short essay plans from memory.',
        'Use active recall: write everything you know about a topic, then check.',
        'Compare different viewpoints on the same event.',
      ],
    ),
  ),
  MapEntry(
    ['english', 'literature', 'writing', 'language arts'],
    StudyGuide(
      subject: 'English and Literature',
      summary: 'Read closely and practise writing regularly.',
      methods: [
        'Annotate texts as you read: themes, techniques and key quotes.',
        'Learn a small set of key quotes per text and what each shows.',
        'Plan and write timed essays, then compare them with strong examples.',
        'Read widely to build vocabulary and a feel for style.',
        'Rewrite weak paragraphs after feedback instead of only reading comments.',
      ],
    ),
  ),
  MapEntry(
    ['french', 'spanish', 'german', 'swahili', 'arabic', 'chinese', 'language', 'languages'],
    StudyGuide(
      subject: 'Languages',
      summary: 'Short, frequent practice beats long, rare sessions.',
      methods: [
        'Practise a little every day. Even 15 minutes helps more than one long weekly session.',
        'Learn words in phrases and sentences, not as isolated lists.',
        'Use flashcards with spaced repetition for vocabulary.',
        'Speak out loud, even to yourself, and write short texts regularly.',
        'Listen to real audio (songs, podcasts, videos) in the language.',
      ],
    ),
  ),
  MapEntry(
    ['computer', 'computer science', 'programming', 'coding', 'ict', 'it', 'cs'],
    StudyGuide(
      subject: 'Computer Science',
      summary: 'You learn programming by building and debugging.',
      methods: [
        'Write code yourself every day. Do not only read or watch tutorials.',
        'Build small projects that use what you just learned.',
        'When stuck, trace the code by hand and read the error message carefully.',
        'Rewrite a solution from memory the next day.',
        'Explain how an algorithm works in plain words before coding it.',
      ],
    ),
  ),
];

// Finds the best guide for the subject name the student typed
StudyGuide guideFor(String subject) {
  final s = subject.toLowerCase().trim();
  for (final entry in _guides) {
    for (final keyword in entry.key) {
      if (s == keyword || s.contains(keyword)) {
        return entry.value;
      }
    }
  }
  return _general;
}
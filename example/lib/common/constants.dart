class FortuneSlice {
  const FortuneSlice({
    required this.label,
    required this.weight,
  }) : assert(weight > 0, 'FortuneSlice.weight must be > 0');

  final String label;
  final double weight;
}

class Constants {
  static final List<String> fortuneValues =
      weightedFortuneValues.map((slice) => slice.label).toList(growable: false);

  static const List<FortuneSlice> weightedFortuneValues = <FortuneSlice>[
    FortuneSlice(label: 'Grogu', weight: 4.5),
    FortuneSlice(label: 'Mace Windu', weight: 2.0),
    FortuneSlice(label: 'Obi-Wan Kenobi', weight: 3.5),
    FortuneSlice(label: 'Han Solo', weight: 1.5),
    FortuneSlice(label: 'Luke Skywalker', weight: 3.0),
    FortuneSlice(label: 'Darth Vader', weight: 5.0),
    FortuneSlice(label: 'Yoda', weight: 4.0),
    FortuneSlice(label: 'Ahsoka Tano', weight: 1.0),
  ];
}

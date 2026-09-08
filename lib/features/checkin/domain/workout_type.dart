enum WorkoutType {
  musculacao('musculacao', 'Musculação'),
  corrida('corrida', 'Corrida'),
  caminhada('caminhada', 'Caminhada'),
  ciclismo('ciclismo', 'Ciclismo'),
  natacao('natacao', 'Natação'),
  funcional('funcional', 'Funcional'),
  outro('outro', 'Outro');

  const WorkoutType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static WorkoutType fromDb(String value) {
    return WorkoutType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => WorkoutType.outro,
    );
  }
}

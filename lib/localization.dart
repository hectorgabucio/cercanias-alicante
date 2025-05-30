const Map<String, Map<String, String>> translations = {
  'es': {
    'appTitle': 'Cercanías Alicante Murcia',
    'origin': 'Origen',
    'destination': 'Destino',
    'selectOrigin': 'Selecciona origen',
    'selectDestination': 'Selecciona destino',
    'swapTooltip': 'Intercambiar origen y destino',
    'today': 'Hoy',
    'tomorrow': 'Mañana',
    'showPast': 'Mostrar trenes pasados',
    'searchStation': 'Buscar estación...',
    'past': 'Pasado',
    'duration': 'Duración',
    'train': 'Tren',
    'settings': 'Ajustes',
    'language': 'Idioma',
    'save': 'Guardar',
    'defaultOrigin': 'Origen por defecto',
    'defaultDestination': 'Destino por defecto',
    'selectLanguage': 'Selecciona idioma',
    'spanish': 'Español',
    'english': 'Inglés',
    'departure': 'Salida',
    'arrival': 'Llegada',
    'search': 'Buscar',
    'from': 'Desde',
    'to': 'Hasta',
    'noResults': 'Lo siento, no se han encontrado resultados para esta búsqueda.',
  },
  'en': {
    'appTitle': 'Cercanías Alicante Murcia',
    'origin': 'Origin',
    'destination': 'Destination',
    'selectOrigin': 'Select origin',
    'selectDestination': 'Select destination',
    'swapTooltip': 'Swap origin and destination',
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'showPast': 'Show past trains',
    'searchStation': 'Search station...',
    'past': 'Past',
    'duration': 'Duration',
    'train': 'Train',
    'settings': 'Settings',
    'language': 'Language',
    'save': 'Save',
    'defaultOrigin': 'Default origin',
    'defaultDestination': 'Default destination',
    'selectLanguage': 'Select language',
    'spanish': 'Spanish',
    'english': 'English',
    'departure': 'Departure',
    'arrival': 'Arrival',
    'search': 'Search',
    'from': 'From',
    'to': 'To',
    'noResults': 'Sorry, no results found for this.',
  }
};

String t(String lang, String key) => translations[lang]?[key] ?? key;

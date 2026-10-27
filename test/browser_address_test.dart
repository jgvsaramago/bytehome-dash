import 'package:bytehomedash/src/kiosk/browser/browser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => SearchEngine.current.value = SearchEngine.google);

  test('full addresses open as they are', () {
    expect(browserAddressFor('https://www.publico.pt/desporto'), 'https://www.publico.pt/desporto');
    expect(browserAddressFor('http://192.168.1.10:8123'), 'http://192.168.1.10:8123');
  });

  test('things that look like addresses open', () {
    expect(browserAddressFor('publico.pt'), 'https://publico.pt');
    expect(browserAddressFor('www.ipma.pt/pt/otempo'), 'https://www.ipma.pt/pt/otempo');
    expect(browserAddressFor('192.168.1.1'), 'http://192.168.1.1');
    expect(browserAddressFor('localhost:3000'), 'http://localhost:3000');
    expect(browserAddressFor('homeassistant.local:8123/lovelace'), 'http://homeassistant.local:8123/lovelace');
    expect(browserAddressFor('homeassistant:8123'), 'http://homeassistant:8123');
  });

  test('about: and data: addresses open as they are', () {
    expect(browserAddressFor('about:blank'), 'about:blank');
    expect(browserAddressFor('data:text/html,<p>olá mundo</p>'), 'data:text/html,<p>olá mundo</p>');
  });

  test('anything else is searched', () {
    expect(browserAddressFor('receita bacalhau à brás'), 'https://www.google.com/search?q=receita+bacalhau+%C3%A0+br%C3%A1s');
    expect(browserAddressFor('meteorologia'), 'https://www.google.com/search?q=meteorologia');
    expect(browserAddressFor('e.g'), 'https://www.google.com/search?q=e.g');
    expect(browserAddressFor('what is 1.5 kg'), startsWith('https://www.google.com/search?q='));
  });

  test('searches use the chosen engine', () {
    SearchEngine.current.value = SearchEngine.duckduckgo;
    expect(browserAddressFor('farmácias'), 'https://duckduckgo.com/?q=farm%C3%A1cias');
  });
}

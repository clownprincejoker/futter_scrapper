import 'package:get/get.dart';
import 'package:scrapper_test/constants.dart';
import 'package:scrapper_test/error_page.dart';
import 'package:scrapper_test/product_model.dart';
import 'package:scrapper_test/providers/scrapping_provider_mixin.dart';
import 'package:uuid/uuid.dart';
import 'package:web_scraper/web_scraper.dart';

class RyansScrapper with Scrapper {
  RyansScrapper() {
    siteUrl = Constants.RYANS_BASE_URL;
    categoryUrls = Constants.RYANS_CATEGORY_LIST;
    localUrl = Constants.RYANS_PRODUCT_INDEX_URL;
  }

  @override
  getAllProductInfo({required category, required page}) async {
    WebScraper webScraper = WebScraper(siteUrl);

    final nameList = [];
    final urlList = [];
    final thumbnailList = [];
    final priceList = [];
    List<BasicProductInfoModel> productList = [];

    var uuid = Uuid();

    try {
      var url = localUrl
          .replaceAll('[1]', '${categoryUrls[category]}')
          .replaceAll('[2]', '$page');

      if (await webScraper.loadWebPage(url)) {
        // Scrapping Title, Url
        webScraper.getElement(
          'div.product-content-info > a.product-title-grid',
          ['href'],
        ).forEach((element) {
          final name = element['title'];
          final url = element['attributes']['href'];
          nameList.add(name);
          urlList.add(url);
        });

        // Scrapping Thumbnail
        webScraper.getElement(
          'div.product-thumb > a > img',
          ['src'],
        ).forEach((element) {
          final thumbnail = element['attributes']['src'];
          thumbnailList.add(thumbnail);
        });

        // Scrapping Price
        webScraper.getElement(
          'div.price-label > div.special-price > span',
          [],
        ).forEach((element) {
          final price = int.parse(
            element['title'].replaceAll(RegExp('[^0-9]'), ''),
          );
          priceList.add(price);
        });

        // Populating ProductInfo List
        for (var i = 0; i < nameList.length; i++) {
          productList.add(
            BasicProductInfoModel.fromMap(
              {
                'id': uuid.v5(
                  Uuid.NAMESPACE_URL,
                  '$siteUrl$localUrl/item$i',
                ),
                'title': nameList[i],
                'url': urlList[i],
                'thumb': thumbnailList[i],
                'price': priceList[i],
              },
            ),
          );
        }

        // For Debugging
        // productList.forEach((element) {
        //   print(element);
        // });
        print('Scrapping Succesful');
      } else {
        print('Scrapping Unsuccesful');
        throw Exception('Api Connection Failed');
      }
    } catch (e) {
      Get.to(
        () => ErrorPage(
          error: Exception('Check Your Internet Connection! $e'),
        ),
      );
    }

    // Returning ProductInfo List
    return productList;
  }

  @override
  checkNextPage({required category, required page}) async {
    WebScraper webScraper = WebScraper(siteUrl);

    try {
      var url = localUrl
          .replaceAll('[1]', '${categoryUrls[category]}')
          .replaceAll('[2]', '$page');

      if (await webScraper.loadWebPage(url)) {
        var prices = webScraper.getElement(
          'div.price-label > div.special-price > span',
          [],
        );

        if (prices.length > 0) {
          return Future<bool>.value(true);
        } else {
          return Future<bool>.value(false);
        }
      } else {
        return Future<bool>.value(false);
      }
    } catch (e) {
      return Future<bool>.value(false);
    }
  }
}

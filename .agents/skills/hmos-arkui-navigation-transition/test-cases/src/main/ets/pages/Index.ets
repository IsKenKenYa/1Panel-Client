import { DetailPage } from './DetailPage';
import { ProfilePage } from './ProfilePage';
import { NewsDetail } from './NewsDetail';
import { ProductDetail } from './ProductDetail';
import { FeedbackPage } from './FeedbackPage';

@Entry
@Component
struct Index {
  @Provide pathStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'detailPage') {
      DetailPage()
    } else if (name === 'profilePage') {
      ProfilePage()
    } else if (name === 'newsDetail') {
      NewsDetail()
    } else if (name === 'productDetail') {
      ProductDetail()
    } else if (name === 'feedback') {
      FeedbackPage()
    } else {
      Dest()
    }
  }

  aboutToAppear(): void {
    this.pathStack.pushPath({ name: 'Dest' })
  }

  build() {
    Navigation(this.pathStack) {

    }
    .navDestination(this.pageMap)
    .hideNavBar(true)
  }
}

@Component
struct Dest {
  @Consume pathStack: NavPathStack;
  @State name: string = 'NA';

  build() {
    NavDestination() {
      HomeBody()
    }
    .title("Navigation System")
  }
}

@Component
struct HomeBody {
  @Consume pathStack: NavPathStack;
  build() {
    Column() {
      Column() {
        Text('Detail Page')
      }
      .width('85%')
      .onClick(() => {
        this.pathStack.pushPath({ name: "detailPage"})
      })
      Column() {
        Text('Profile Page')
      }
      .width('85%')
      .onClick(() => {
        this.pathStack.pushPath({ name: "profilePage"})
      })
      Column() {
        Text('News Page')
      }
      .width('85%')
      .onClick(() => {
        this.pathStack.pushPath({ name: "newsDetail"})
      })
      Column() {
        Text('Product Page')
      }
      .width('85%')
      .onClick(() => {
        this.pathStack.pushPath({ name: "productDetail"})
      })
      Column() {
        Text('Feedback Page')
      }
      .width('85%')
      .onClick(() => {
        this.pathStack.pushPath({ name: "feedback"})
      })
    }
  }
}
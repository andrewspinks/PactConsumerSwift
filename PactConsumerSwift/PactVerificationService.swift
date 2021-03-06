import Foundation
import Alamofire

@objc public class PactVerificationService {
  public let url: String
  public let port: Int
  public var baseUrl: String {
    get {
      return "\(url):\(port)"
    }
  }
  
  enum Router: URLRequestConvertible {
    static var baseURLString = "http://example.com"
    
    case Clean()
    case Setup([String: AnyObject])
    case Verify()
    case Write([String: AnyObject])
    
    var method: Alamofire.Method {
      switch self {
      case .Clean:
        return .DELETE
      case .Setup:
        return .POST
      case .Verify:
        return .GET
      case .Write:
        return .POST
      }
    }
    
    var path: String {
      switch self {
      case .Clean:
        return "/interactions"
      case .Setup:
        return "/interactions"
      case .Verify:
        return "/interactions/verification"
      case .Write:
        return "/pact"
      }
    }
    
    var URLRequest: NSURLRequest {
      let URL = NSURL(string: Router.baseURLString)!
      let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
      mutableURLRequest.HTTPMethod = method.rawValue
      mutableURLRequest.setValue("true", forHTTPHeaderField: "X-Pact-Mock-Service")
      
      switch self {
      case .Setup(let parameters):
        return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
      case .Write(let parameters):
        return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
      default:
        return mutableURLRequest
      }
    }
  }
  
  public init(url: String = "http://localhost", port: Int = 1234) {
    self.url = url
    self.port = port
    Router.baseURLString = baseUrl
  }
  
  func clean(#success: () -> Void, failure: () -> Void) -> Void {
    Alamofire.request(Router.Clean())
              .validate()
              .responseString(RequestHandler(success: success, failure: failure).requestHandler())
  }
  
  func setup (interactions: [Interaction], success: () -> Void, failure: () -> Void) -> Void {
    // TODO allow multiple interactions
    //    for interaction in interactions {
    //      Alamofire.request(Router.Setup(interaction.asDictionary())).validate().response { (_, _, _, error) in
    //        println(error)
    //      }
    //    }
    
    //    interactions.removeAll()
    Alamofire.request(Router.Setup(interactions[0].payload()))
              .validate()
              .responseString(RequestHandler(success: success, failure: failure).requestHandler())
  }
  
  func verify(#success: () -> Void, failure: () -> Void) -> Void {
    Alamofire.request(Router.Verify())
              .validate()
              .responseString(RequestHandler(success: success, failure: failure).requestHandler())
  }
  
  func write(#provider: String, consumer: String, success: () -> Void, failure: () -> Void) -> Void {
    Alamofire.request(Router.Write([ "consumer": [ "name": consumer ], "provider": [ "name": provider ] ]))
              .validate()
              .responseString(RequestHandler(success: success, failure: failure).requestHandler())
  }

  private struct RequestHandler {
    let success: () -> Void
    let failure: () -> Void

    func requestHandler() -> (NSURLRequest, NSHTTPURLResponse?, String?, NSError?) -> Void {
      return {
        (_, _, response, error) in
        if let error = error {
          println(error)
          self.failure()
        } else {
          println(response)
          self.success()
        }
      }
    }
  }
}
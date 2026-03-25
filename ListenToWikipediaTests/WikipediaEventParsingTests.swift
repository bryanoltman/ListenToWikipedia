import Foundation
import Testing

@testable import ListenToWikipedia

struct WikipediaEventParsingTests {
  @Test func validArticleEdit() {
    let json = """
      {"page_title":"Test Article","ns":"Main","change_size":42,"is_anon":false,"is_bot":false,"url":"https://en.wikipedia.org/wiki/Test"}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    guard case .articleEdit(let edit) = event else {
      Issue.record("Expected articleEdit")
      return
    }
    #expect(edit.pageTitle == "Test Article")
    #expect(edit.changeSize == 42)
    #expect(edit.isAnonymous == false)
    #expect(edit.isBot == false)
    #expect(edit.language == "en")
    #expect(edit.url == URL(string: "https://en.wikipedia.org/wiki/Test"))
  }

  @Test func validNewUser() {
    let json = """
      {"page_title":"Special:Log/newusers","user":"TestUser123"}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "de")
    guard case .newUser(let user) = event else {
      Issue.record("Expected newUser")
      return
    }
    #expect(user.username == "TestUser123")
    #expect(user.language == "de")
  }

  @Test func missingPageTitleDefaultsToEmpty() {
    let json = """
      {"ns":"Main","change_size":10}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    guard case .articleEdit(let edit) = event else {
      Issue.record("Expected articleEdit")
      return
    }
    #expect(edit.pageTitle == "")
  }

  @Test func nonMainNamespaceReturnsNil() {
    let json = """
      {"page_title":"Talk:Something","ns":"Talk","change_size":5}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    #expect(event == nil)
  }

  @Test func missingNamespaceReturnsNil() {
    let json = """
      {"page_title":"Some Article","change_size":5}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    #expect(event == nil)
  }

  @Test func malformedJsonReturnsNil() {
    let event = WikipediaEvent.fromJsonString( "not json at all", language: "en")
    #expect(event == nil)
  }

  @Test func emptyJsonReturnsNil() {
    let event = WikipediaEvent.fromJsonString( "{}", language: "en")
    #expect(event == nil)
  }

  @Test func missingChangeSizeDefaultsToZero() {
    let json = """
      {"page_title":"Article","ns":"Main"}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    guard case .articleEdit(let edit) = event else {
      Issue.record("Expected articleEdit")
      return
    }
    #expect(edit.changeSize == 0)
  }

  @Test func newUserMissingUsernameReturnsNil() {
    let json = """
      {"page_title":"Special:Log/newusers"}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    #expect(event == nil)
  }

  @Test func caseInsensitiveNamespace() {
    let json = """
      {"page_title":"Article","ns":"MAIN","change_size":1}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    #expect(event != nil)
  }

  @Test func anonymousAndBotFlags() {
    let json = """
      {"page_title":"Bot Edit","ns":"Main","change_size":-50,"is_anon":true,"is_bot":true}
      """
    let event = WikipediaEvent.fromJsonString( json, language: "en")
    guard case .articleEdit(let edit) = event else {
      Issue.record("Expected articleEdit")
      return
    }
    #expect(edit.isAnonymous == true)
    #expect(edit.isBot == true)
    #expect(edit.changeSize == -50)
  }
}

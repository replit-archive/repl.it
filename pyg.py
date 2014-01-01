#!/usr/bin/python2

import re, sys
from pygments import highlight
from pygments.lexers import get_lexer_by_name, JavascriptLexer, FactorLexer
from pygments.formatters import HtmlFormatter
from pygments.token import *
from pygments.lexer import RegexLexer

class UnlambdaLexer(RegexLexer):
  name = 'Unlambda'
  aliases = ['unlambda']
  filenames = ['*.u']

  tokens = {
    'root': [
      (r'#.*\n', Comment.Single),
      (r'd', Comment.Preproc),
      (r'\..', Generic.Output),
      (r'[sk]', Keyword.Declaration),
      (r'[cv]', Keyword.Type),
      (r'i', Keyword.Constant),
      (r'[@ried|?]', Keyword.Pseudo),
      (r'`', Operator),
      (r'.', Text),
    ]
  }

class QBasicLexer(RegexLexer):
  name = 'QBasic'
  aliases = ['qbasic']
  filenames = ['*.bas']

  tokens = {
    'root': [
      (r'\'.*\n', Comment.Single),
      (r'\"[^"]*\"', Literal.String),
      (r'&H[\da-fA-F]+|\d*\.\d+|\d+', Literal.Number),
      (r'[-+*/<>=\\]', Operator),
      (r'[()\[\]]', Punctuation),
      (r'\b(AND|AS|CASE|CONST|DATA|DECLARE|DEF|DEFINT|DIM|DO|ELSE|END|EXIT|FOR|FUNCTION|GOSUB|GOTO|IF|INPUT|LINE|LOOP|MOD|NEXT|NOT|OR|POKE|PRINT|RESTORE|RETURN|SEG|SELECT|SHARED|STATIC|STEP|SUB|TAB|THEN|TO|TYPE|UNTIL|USING|VIEW|WEND|WHILE|XOR)\b', Keyword),
      (r'^([a-zA-Z][a-zA-Z0-9_]*:|\d+)', Name.Label),
      (r'[a-zA-Z_][a-zA-Z0-9_]*(\$|%|#|&|!)?', Name.Variable),
      (r'.', Text),
    ]
  }

class LOLCODELexer(RegexLexer):
  name = 'LOLCODE'
  aliases = ['lolcode']
  filenames = ['*.bas']

  tokens = {
    'root': [
      (r'^OBTW\b.*?\bTLDR\b', Comment.Multiline),
      (r'\bBTW\b.*\n', Comment.Single),
      (r'\b(NERFIN|YA\s+RLY|BUKKIT|IS\s+NOW\s+A|MEBBE|GIMMEH|TIL|UPPIN|MKAY|TROOF|INTA|YR|!|NUMBR|OMG|NUMBAR|IF\s+U\s+SAY\s+SO|YARN|VISIBLE|I\s+HAS\s+A|IM\s+OUTTA\s+YR|IM\s+IN\s+YR|A|HAI|NO\s+WAI|GTFO|AN|R|FOUND\s+YR|OMGWTF|FAIL|O\s+RLY?|WTF\?|NOOB|HOW\s+DUZ\s+I|WIN|MAEK|OIC|PUTZ|KTHXBYE|ITZ|WILE|AT)(\b|(?=\s))', Keyword),
      (r'\b(NOT|LENGZ\s+OF|CHARZ\s+OF|ORDZ\s+OF|SUM\s+OF|DIFF\s+OF|PRODUKT\s+OF|QUOSHUNT\s+OF|MOD\s+OF|BIGGR\s+OF|SMALLR\s+OF|BOTH\s+OF|EITHER\s+OF|WON\s+OF|BOTH\s+SAEM|DIFFRINT|ALL\s+OF|ANY\s+OF|SMOOSH|N)\b', Operator.Word),
      (r'"(?::(?:[)>o":]|\([\dA-Fa-f]+\)|\{[A-Za-z]\w*\}|\[[^\[\]]+\])|[^":])*"', Literal.String),
      (r'-?(\d+|\d+\.\d*|\.\d+)', Literal.Number),
      (r'[a-zA-Z]\w*', Name.Variable),
      (r',', Punctuation),
      (r'.', Text),
    ]
  }

class BloopLexer(RegexLexer):
  name = 'Bloop'
  aliases = ['bloop']
  filenames = ['*.bloop']

  flags = re.IGNORECASE | re.DOTALL
  tokens = {
    'root': [
      (r'/\*.*?\*/', Comment.Multiline),
      (r"'[^']*'", Literal.String),
      (r'-?\d+', Literal.Number),
      (r'\b(DEFINE|PROCEDURE|BLOCK|LOOP|AT|MOST|TIMES|MU_LOOP|CELL|OUTPUT|YES|NO|QUIT|ABORT|IF|THEN|AND|OR|PRINT|BEGIN|END)(\b|(?=\s))', Keyword),
      (r'[A-Z]\w*', Name),
      (r'[+*!=<>(){}":;,.-\[\]]', Punctuation),
      (r'.', Text),
    ]
  }

class EmoticonLexerHelper(RegexLexer):
  tokens = {
    'root': [
      (r'\*\*([^*]|\*[^*])*\*\*', Comment),
      (r'\S+[OC<>\[\]VD@PQ7L#${}\\/()|3E*]((?=\s)|$)', Keyword),
      (r'\S+', Literal.String),
      (r'-?\d+', Literal.Number),
      (r'.', Text),
    ]
  }

class EmoticonLexer(EmoticonLexerHelper):
  name = 'Emoticon'
  aliases = ['emoticon']
  filenames = ['*.emo']

  def get_tokens_unprocessed(self, text):
    for index, token, value in EmoticonLexerHelper.get_tokens_unprocessed(self, text):
      if token is Keyword:
        yield index, Name, value[:-2]
        yield index + len(value) - 2, Operator, value[-2]
        yield index + len(value) - 2, Keyword, value[-1]
      else:
        yield index, token, value

class KaffeineLexer(JavascriptLexer):
  name = 'Kaffeine'
  aliases = ['kaffeine']
  filenames = ['*.k']

  def get_tokens_unprocessed(self, text):
    for index, token, value in JavascriptLexer.get_tokens_unprocessed(self, text):
      if token is Error and value in ['#', '@']:
        token_type = Name.Tag if value == '#' else Keyword
        yield index, token_type, value
      else:
        yield index, token, value

class JavascriptNextLexer(JavascriptLexer):
  name = 'Javascript.next'
  aliases = ['javascript.next', 'traceur']
  filenames = ['*.jsn']

  EXTRA_KEYWORDS = ['let', 'yield']
  def get_tokens_unprocessed(self, text):
    for index, token, value in JavascriptLexer.get_tokens_unprocessed(self, text):
      if token is Name.Other and value in self.EXTRA_KEYWORDS:
        yield index, Keyword, value
      else:
        yield index, token, value

class MoveLexer(JavascriptLexer):
  name = 'Move'
  aliases = ['move']
  filenames = ['*.mv']

class ForthLexer(FactorLexer):
  name = 'Forth'
  aliases = ['forth']
  filenames = ['*.4th']

class RoyLexer(RegexLexer):
  name = 'Roy'
  aliases = ['roy']
  filenames = ['*.roy']

  tokens = {
    'root': [
      (r'//.*\n', Comment.Single),
      (r'\b(true|false|let|fn|if|then|else|data|type|match|case|do|return|macro|with)\b', Keyword),
      (r'-?\d+', Literal.Number),
      (r'\"[^"]*\"', Literal.String),
      (r'<-|->|=|==|!=|\*|\+\+|\\', Operator),
      (r'.', Text)
    ]
  }

class APLLexer(RegexLexer):
  name = 'APL'
  aliases = ['apl']
  filenames = ['*.apl']

  tokens = {
    'root': [
      (r'.+', Text)
    ]
  }

def getLexer(lexer_name):
  lexers = [value for name, value in globals().items()
            if name.endswith('Lexer') and hasattr(value, 'aliases')]
  for lexer in lexers:
    if lexer_name in lexer.aliases:
      return lexer()
  return get_lexer_by_name(lexer_name)

def main():
  if len(sys.argv) == 2:
    lexer = getLexer(sys.argv[1])
    if lexer:
      result = highlight(sys.stdin.read().decode('utf8'), lexer, HtmlFormatter())
      result = result.replace('<div class="highlight"><pre>', '')
      result = result.replace('</pre></div>', '')
      print result.strip().encode('utf8')
    else:
      print 'Unknown language:', sys.argv[1]
  else:
    print 'Usage: pyg.py language < code.txt'

if __name__ == '__main__':
  main()

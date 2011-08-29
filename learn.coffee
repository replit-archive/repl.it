$ = jQuery
@REPLIT = {}
templates = {}
courses = []
jqconsole = null
lang_course_list = []
current_course = null
$doc = null
$course = null
jsrepl = null
StartPrompt = null
config = null
###
{
  introduction: '''
    CoffeeScript is the Shit!
  '''
  link: 'http://jashkenas.github.com/coffee-script/'
  
  chapters: [
    {
      name: 'Syntax'
      introduction: '''
        The syntax is awesome, comments are like that, semicolons are blah!
      '''
      exercises:[
        {
          name: 'functions'
          text: '''
            XXX
          '''
          questions: [
            prompt: 'write square'
            callback: (AST, _eval) ->
              _eval('square(3)') == 9 and _eval('square(2)') == 4 and _eval('square(10)') == 100
          ]
            
        }
      ]
    }  
  ]
}
###
# Shows a command prompt in the console and waits for input.
ParseCourse = (text) ->
  code = CoffeeScript.compile text, bare: on
  refstack = []
  refstack.current = ()-> @[@length - 1]
  
  setterFactory = (name) -> (value) -> refstack.current()[name] = value
  # Value setter functions.
  introduction = setterFactory 'introduction'
  link = setterFactory 'link'
  text = setterFactory 'text'
  prompt = setterFactory 'prompt'
  callback = setterFactory 'callback'
  success = setterFactory 'success'
  fail = setterFactory 'fail'
  hint = setterFactory 'hint'
  
  defContainerFactory = (arrName, has_name) ->
    (name, def) ->
      def = name if not has_name
      current = refstack.current()
      current[arrName]?= []
      if has_name
        refstack.push {name}
      else
        refstack.push {}
      def()
      current[arrName].push refstack.pop()
        
  Course = (language, title, def) ->
    refstack.push {language, title}
    def()
    return refstack.pop()
  
  chapter = defContainerFactory 'chapters', true
  exercise = defContainerFactory 'exercises', true
  question = defContainerFactory 'questions', false
  return eval(code)

Init = ->
  $doc = $(document)
  $course = $('#course')
  
  # Instantiate jqconsole
  @fak = jqconsole = $('#console').jqconsole ''
  
  #
  # Define templates
  templates.course = '''
    <a href="#" class='button' data-index={{index}}>{{title}}</a>
    ({{language}})
  '''
  templates.courses = '''
    <ul>
      {{#courses}}
      <li>{{>course}}</li>
      {{/courses}}
    </ul>
  '''

  # Get courses
  lang_course_list = []
  for category, languages of @REPLIT.Languages
    for language in languages
      if language.courses?
        for course in language.courses
          course.language = language.name
          course.jsrepl_name = language.jsrepl_name
          course.index = lang_course_list.length
          lang_course_list.push course

  courses_html = Mustache.to_html templates.courses, courses: lang_course_list, templates
  $('#course-selector').append courses_html
  ShowCourses()


class Course
  constructor: (@course, @course_desc) ->
    @templates =
      course: '''
        <h2> {{title}} </h2>
        <a href="{{link}}"> External material </a>
        <h3> Introduction </h3>
        <p> {{introduction}} </p>
        <h3> Chapters </h3>
        <ul>
          {{#chapters}}
            <li><a href="#" class="chapter button">{{name}}</a> {{status}}</li>
          {{/chapters}}
        </ul>
      '''
      chapter: '''
        <h2> {{name}} </h2>
        <p> {{introduction}} </p>
        <ul>
          {{#exercises}}
            <li><a href="#" class="exercise button">{{name}}</a> {{status}}</li>
          {{/exercises}}
        </ul>
        <a class="button back" href="#" >&lt;&lt;Back to course</a>
      '''
      exercise: '''
        <h2> {{name}} </h2>
        <p> {{{markdowned}}} </p>
        <a class="button back" href="#">&lt;&lt;Back to chapters</a>
      '''
      
  LoadLanguage: () ->
    jqconsole.Reset()
    jqconsole.RegisterShortcut 'Z', =>
      jqconsole.AbortPrompt()
      StartPrompt()
    jsrepl.LoadLanguage @course.language, =>
      $('body').toggleClass 'loading'
      $doc.trigger 'language_loaded.Course'
      
  StartCourse: ->
    @Render 'course', @course

  StartChapter: (index, render=true) ->
    @current_chapter = @course.chapters[index]
    @Render 'chapter', @current_chapter if render
  
  StartExercise: (index, render=true) ->
    @current_exercise = @current_chapter.exercises[index]
    @current_exercise.markdowned = () ->
      window.markdown.toHTML this.text
    @Render 'exercise', @current_exercise if render
    @StartQuestionSession 0

  StartQuestionSession: (index, fak) ->
    @current_question = @current_exercise.questions[index]
    jqconsole.Write "Q1. #{@current_question.prompt}  \n"
    StartPrompt = =>
      Evaluate = (command)=>
        if command
          jsrepl.Evaluate command
          config.meta = true
          right = @current_question.callback [], $.proxy(jsrepl.EvaluateSync, jsrepl)
          config.meta = false
          if right
            success = @current_question.success or "Good job!"
            jqconsole.Write success + '<br>', 'success', false
            @NextQuestion index
          else
            jqconsole.ClearPromptText()
            fail = @current_question.fail or "Try again!"
            jqconsole.Write fail + '<br>', 'fail', false
        else
          StartPrompt()
      jqconsole.Prompt true, Evaluate, $.proxy(jsrepl.CheckLineEnd, jsrepl)
    StartPrompt()
  
  NextQuestion: (index) ->
    next_index = index + 1
    next_q = @current_exercise.questions[next_index]
    jqconsole.AbortPrompt()
    if next_q
       @StartQuestionSession next_index
    else
      @current_exercise.status = "complete"
      current_ex_index = $.inArray @current_exercise, @current_chapter.exercises
      next_exercise = @current_chapter.exercises[current_ex_index + 1]
      if next_exercise?
        @StartExercise current_ex_index + 1
      else
        @current_chapter.status = "complete"
        current_ch_index = $.inArray @current_chapter, @course.chapters
        next_chapter = @course.chapters[current_ch_index + 1]
        if next_chapter?
          jqconsole.Write "Chapter completed go to the <a href=\"#\" class=\"button\">next one</a>", 'goto', false
          jqconsole.$console.find('.goto').click ()->
            NavigatorGoto 'chapter', current_ch_index + 1
        else
          @CourseComplete()

  CourseComplete: ->
    alert 'fuck'    

    
  Navigate: (chapter_index, exercise_index) ->
    @StartCourse() if not chapter_index and not exercise_index
    if chapter_index?
      @StartChapter chapter_index, not exercise_index?
    if exercise_index?
      @StartExercise exercise_index
    
  Render: (name, data, attach_nav=true) ->
    nav_class = if name == 'course' then 'chapter' else 'exercise'
    html = Mustache.to_html @templates[name], data, @templates
    $course.empty().append html
    if attach_nav
      $course.find("a.#{nav_class}").click ()->
        #$.nav.pushState '/' + $.nav.getState() + '/' + $(this).index()
        NavigatorGoto 'append', $(this).index()
      $course.find("a.back").click ()->
        NavigatorGoto 'back'
  
ShowCourses = () ->
  jQuery.facebox div: '#course-selector', 'courses'
  $('#facebox  .content.courses a').click (e)->
    NavigatorGoto 'course', $(this).data 'index'
    #$.nav.pushState '/' + $(this).data 'index'

NavigatorGoto = (which, index) ->
  console.log which
  current_state = $.nav.getState()
  [course_index, chapter_index, exercise_index] = current_state.split '/' 
  $.nav.pushState switch which
    when 'course' then "/#{index}"
    when 'chapter' then "/#{course_index}/#{index}"
    when 'exercise' then "/#{course_index}/#{chapter_index}/#{index}"
    when 'append' then "/#{current_state}/#{index}"
    when 'back'
      path = "/#{course_index}"
      path += "/#{chapter_index}" if exercise_index
      path
    else ""
    

NavigationRouter = (path) ->
  [course_path, chapter_path, exercise_path] = path.split '/'
  course_desc = lang_course_list[course_path]
  if course_desc? and (not current_course? or current_course.course_desc != course_desc)
    $doc.trigger 'close.facebox'
    $.get course_desc.file, (data) ->
      course = ParseCourse data
      course.index = course_path
      current_course = new Course course, course_desc
      current_course.LoadLanguage()
      current_course.Navigate chapter_path, exercise_path
  else
    current_course.Navigate chapter_path, exercise_path
      
  
$ ->
  config =
    meta: false
    JSREPL_dir: 'jsrepl/'
    # Receives the result of a command evaluation.
    #   @arg result: The user-readable string form of the result of an evaluation.
    ResultCallback: (result) ->
      if result and not config.meta
        jqconsole.Write '==> ' + result, 'result'
        StartPrompt()
      return result
    
    # Receives an error message resulting from a command evaluation.
    #   @arg error: A message describing the error.
    ErrorCallback: (error) ->
      if not config.meta
        jqconsole.Write String(error), 'error'
        StartPrompt()
      
    # Receives any output from a language engine. Acts as a low-level output
    # stream or port.
    #   @arg output: The string to output. May contain control characters.
    #   @arg cls: An optional class for styling the output.
    OutputCallback: (output, cls) ->
      jqconsole.Write output, cls
      return undefined
      
    # Receives a request for a string input from a language engine. Passes back
    # the user's response asynchronously.
    #   @arg callback: The function called with the string containing the user's
    #     response. Currently called synchronously, but that is *NOT* guaranteed.
    InputCallback: (callback) ->
      jqconsole.Input (result) =>
        try
          callback result
        catch e
          @ErrorCallback e
      return undefined
    
  jsrepl = new JSREPL config
  Init()
  editor = ace.edit 'editor'
  editor.setTheme "ace/theme/twilight"
  window.fas = editor
  $(window).load () ->
    # Hack for chrome and FF 4 fires an additional popstate on window load.
    setup = () ->
      $.nav NavigationRouter
    setTimeout setup, 0
    
  $('a.button').live 'click', (e) -> 
    e.preventDefault()
    
  $('#course-button').click (e)->
    
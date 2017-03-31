###
Codemirror-based input cell

TODO:

 - [ ] need to merge in changes rather than just overwrite when get new changes from remote

###


{React, ReactDOM, rclass, rtypes}  = require('../smc-react')

{CodeMirrorEditor} = require('./codemirror-editor')
{CodeMirrorStatic} = require('./codemirror-static')

exports.CodeMirror = rclass
    propTypes :
        actions    : rtypes.object
        id         : rtypes.string.isRequired
        options    : rtypes.immutable.Map.isRequired
        value      : rtypes.string.isRequired
        font_size  : rtypes.number  # not explicitly used, but critical to re-render on change so Codemirror recomputes itself!
        is_focused : rtypes.bool.isRequired
        cursors    : rtypes.immutable.Map
        complete   : rtypes.immutable.Map

    shouldComponentUpdate: (next) ->
        return \
            next.id         != @props.id or \
            next.options    != @props.options or \
            next.value      != @props.value or \
            next.font_size  != @props.font_size or\
            next.is_focused != @props.is_focused or\
            next.cursors    != @props.cursors or \
            next.complete   != @props.complete

    render: ->
        if @props.is_focused and not @props.complete?
            <CodeMirrorEditor
                actions   = {@props.actions}
                id        = {@props.id}
                options   = {@props.options}
                value     = {@props.value}
                font_size = {@props.font_size}
                cursors   = {@props.cursors}  />
        else
            <CodeMirrorStatic
                actions   = {@props.actions}
                id        = {@props.id}
                options   = {@props.options}
                value     = {@props.value}
                font_size = {@props.font_size}
                cursors   = {@props.cursors}
                complete  = {@props.complete} />

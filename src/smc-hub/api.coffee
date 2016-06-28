###
SMC API

mounted at /api/#{APIVER}/ and hence makes it possible to update endpoints to higher versions

the mounting step uses the router object, which is created in hub_http_server and passed in here
###

misc      = require('smc-util/misc')
{defaults, required} = misc
misc_node = require('smc-util-node/misc_node')
express   = require('express')

setup_endpoint = (req, res, done) ->
    res.header('Content-Type', 'text/plain')
    res.header('Cache-Control', 'private, no-cache, no-store, must-revalidate')
    res.header('Expires', '-1')
    res.header('Pragma', 'no-cache')
    done?()

exports.init_smc_api = (opts, router) ->

    APIVER = '1' # (indicates version 1)
    pw_reset_url = "#{opts.base_url}/api/#{APIVER}/password_reset"

    # poor mans template, good enough for now
    mk_page = (title, body, error=false, tryagain=false) ->
        error_html = if error then "<h1 style='color:#e33;'>There is a problem!</h1>" else ''
        tryagain_html = if tryagain then "<p><a href='#{pw_reset_url}'>Try again please!</a></p>" else ''

        return """<!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <title>#{title} - SageMathCloud</title>
          <style>
          * {font-family: sans-serif;}
          body {font-size: 110%;}
          </style>
        </head>
        <body>
        #{error_html}
        #{body}
        #{tryagain_html}
        </body>
        </html>
        """

    # the expressjs instance
    smcapi = express()

    smcapi.all '/*', setup_endpoint

    smcapi.all '/', (req, res) ->
        setup_endpoint(req, res)
        res.send(JSON.stringify(name:'SageMathCloud API', version: 1))


    smcapi.get '/password_reset', (req, res) ->
        res.header('Content-Type', 'text/html')
        form = mk_page('Password Reset', """
        <h1>Request password reset</h1>
        <p>Enter your account's email address to receive password reset instructions.</p>
        <form action="#{pw_reset_url}" method="post">
          <label for="email">Email address:</label>
          <input name="email" placeholder="your.email@address.com" value="" size="40">
          <br/><br/>
          <button>Request reset</button>
        </form>
        """)
        res.send(form)

    password_reset_step1 = (req, res, next) ->
        # ATTN no logging of req.body, contains the user's new password
        # winston.debug("smcapi/password_reset/POST: #{misc.to_json(req.body)}")
        res.header('Content-Type', 'text/html')
        email = req.body.email
        if email?
            if not misc.is_valid_email_address(email)
                msg = mk_page('Invalid Email Address', """
                <p><b>'#{email}' is not a valid email address.</b></p>
                """, error=true, tryagain=true)
                res.send(msg)
                next()
                return

            {email_forgot_password_impl} = require('./hub')
            email_forgot_password_impl email, '0.0.0.0', (err) ->
                if err?
                    req.err = err
                    opts.database.get_site_settings
                        cb : (err, settings) ->
                            if err?
                                req.err = "#{req.err}/#{err}"
                            if err or not settings
                                req.help_email = ''
                            else
                                req.help_email = settings.help_email ? ''
                            next()
                else
                    res.send(mk_page("Check email account",
                                     """
                                     <h1 style='color:#3e3;'>Success: reset email sent</h1>
                                     <p>Please check your email account for '#{email}' to reset your password and
                                     don't forget to inspect your spam folder!</p>
                                     """))
                    next()
            return

            password = req.body.password
            if password?
                token = req.body.token
                res.header('Content-Type', 'text/html')
                res.write("TESTING: password of length #{password.length} and token: #{token}")
                {reset_forgot_password_impl} = require('./hub')
                reset_forgot_password_impl token, password, (err) ->
                    if err?
                        res.write("<p>ERROR saving new password: #{misc.to_json(err)}</p>")
                    else
                        res.write("<p>Your new password has been saved.</p>")
                        res.write("<p>Please <a href='#{opts.base_url}'>login again</a>!</p>")
                next()
                return

            res.write(JSON.stringify(error: 'action unknown'))
            next()

    smcapi.post '/password_reset', [password_reset_step1], (req, res) ->
        if req.help_email?
            {site_settings_conf} = require('smc-util/schema')
            email = site_settings_conf.help_email.default
            if req.help_email
                email = req.help_email
            msg = mk_page("Problem",
                """
                <p>Problem requesting a password reset: #{misc.to_json(req.err)}</p>
                <p>Possible reasons why there is a problem:
                <ul>
                  <li>You mistyped your email address – either right now or when you registered.</li>
                  <li>Maybe you did register using another email address?</li>
                  <li>If you did register with a federated account provided via Google, GitHub, Twitter or others,
                      your email address might not be known to us.</li>
                </ul>
                </p>
                <p>Contact: <a href='mailto:#{email}'>#{email}</a></p>
                """, error=true, tryagain=true)
            res.send(msg)

    smcapi.get '/password_reset/*', (req, res) ->
        token = req.path[16..] # only the '*' part of the path
        # winston.debug("smcapi/password_reset/token: #{token}")
        res.header('Content-Type', 'text/html')
        form = mk_page('Reset Password', """
        <p>Please enter the new password for your account:</p>
        <form action="#{pw_reset_url}" method="post">
          <label for="password">Password:</label>
          <input name="password" value="" size="40" type="password">
          <input type="hidden" name="token" value="#{token}">
          <br/><br/>
          <button>Reset Password</button>
        </form>
        """)
        res.write(form)

    router.use("/api/#{APIVER}", smcapi)
    # ~~ END SMC API









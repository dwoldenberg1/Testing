<?php

class Game extends CI_Controller {

	public function __construct()
	{
		parent::__construct();
		$this->load->model('user_model');
	}

	public function view($page = 'home')
	{
		if ( ! file_exists('application/views/pages/'.$page.'.php'))
		{
			// Whoops, we don't have a page for that!
			show_404();
		}

		$data['title'] = ucfirst($page); // Capitalize the first letter

		$this->load->view('templates/header', $data);
		$this->load->view('pages/'.$page, $data);
	}
	
	public function index()
	{
		$data['previous'] = 'home';
		$data['title'] = 'Game';
		
		$this->load->view('templates/header', $data);
		$this->load->view('pages/game');
		//$this->load->view('templates/footer');
		
	}
	
	public function updateScore()
	{
		$user=$_POST['user'];
		$previous=$_POST['previous'];
		$score=$_POST['score'];
		
		$this->user_model->updateHighScore($score, $user);
	}
	
	public function logout()
	{
		$this->user_model->logout();
		$this->main();
	}

	public function validate($previous = 'home')
	{
		$logged_in = $this->session->userdata('logged_in');
		if($logged_in === FALSE)
		{
			$newdata = $this->prompt_login();
			$this->user_model->setAccount($newdata);
		}
		else {
			$account = $this->session->all_userdata();
			$account['highscore']=$this->user_model->get_highScore($account['username']);
			$this->main($previous, $account);
        }
	}

	public function prompt_login()
	{
		$data['title']="Login";
		if ($_SERVER['REQUEST_METHOD'] === 'POST') 
		{
		
			$this->load->helper('form');
			$this->load->library('form_validation');
			
			$this->form_validation->set_rules('user', 'Username', 'required');
			$this->form_validation->set_rules('pass', 'Password', 'required');
			
			if ($this->form_validation->run() == FALSE || $this->user_model->isAccount($this->input->post('user'), $this->input->post('pass')) == FALSE){
				print '<script type="text/javascript">'; 
				print 'alert("Either the username does not exist or the password isn\'t valid.")'; 
				print '</script>';
				$this->load->view('templates/header', $data);
				$this->load->view('templates/login');	
			}
			else{
					
					/*$query = $this->db->get_where('accounts', 'username', $this->input->post('user'));
					$row = $query->row_array();
					if($this->input->post('pass') === $row['password_encrypted'])
					{*/
						$userData = array(
							'username' => $this->input->post('user'),
							'password' => $this->input->post('pass'),
							'email' => $this->user_model->get_email($this->input->post('user')),//$this->input->post('email')
							'logged_in' => TRUE,
							'highscore' => $this->user_model->get_highscore($this->input->post('user'))
							);
						$this->main('home', $userData);
						return $userData;
					/*}
					print '<script type="text/javascript">'; 
					print 'alert("The password is incorrect for that usrname.")'; 
					print '</script>';
					$this->load->view('templates/login');*/
			}
		}
		else
		{
			$this->load->helper('form');
			$this->load->library('form_validation');

			$this->form_validation->set_rules('user', 'Username', 'required');
			$this->form_validation->set_rules('pass', 'Password', 'required');
			
			$this->load->view('templates/header', $data);
			$this->load->view('templates/login');	
		}
	}

	public function new_user()
	{
		$this->load->helper('form');
		$this->load->library('form_validation');

		$this->form_validation->set_rules('user', 'Username', 'required||max_length[12]|is_unique[accounts.username]');
		$this->form_validation->set_rules('pass', 'Password', 'required');
		$this->form_validation->set_rules('email', 'Email', 'required|valid_email|is_unique[accounts.email]');
		
		$data['title'] = 'Create an Account';

		if ($this->form_validation->run() == FALSE){
			$this->load->view('templates/header', $data);
			$this->load->view('templates/new_user', $data);	
		}
		else{
			$account = $this->user_model->create_account();
			print '<script type="text/javascript">'; 
			print 'alert("Account created succesfully!")'; 
			print '</script>';
			$this->main('home', $account);
		}

	}
	
	public function leaderboard()
	{
		$data['users'] = $this->user_model->get_Users();
		$data['title'] = 'Leaderboard';

		$this->load->view('templates/header', $data);
		/*foreach ($data['users'] as $array):
			echo implode(", ", $array);
			echo " | ";
		endforeach;*/
		$this->load->view('templates/leaderboard', $data);
	}
	
	public function main($page = 'home', $account = array())
	{
		/*print '<script type="text/javascript">'; 
		print 'alert('.implode("|",$account)..$account['username'].')'; 
		print '</script>';*/
		if($page === "new_user") {
			$data['previous'] = ('Home');
		}
		$data['previous'] = ($page);
		$data['title'] = ucfirst($page); // Capitalize the first letter
		if(count($account) > 0) {
			$data['logged_in']=$account['logged_in'];
			$data['username']=$account['username'];
			$data['highscore']=$account['highscore'];
		}
		$data['bestUser']=$this->user_model->highestUser();
		$data['bestScore']=$this->user_model->highestScore();
		$this->load->view('templates/header', $data);
		$this->load->view('pages/game', $data);
	}
}
?>